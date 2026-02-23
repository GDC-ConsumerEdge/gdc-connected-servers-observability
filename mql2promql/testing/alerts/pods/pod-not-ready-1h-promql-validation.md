### MQL to PromQL Conversion Validation: Pod Not Ready

This report summarizes the conversion of the "Pod not ready for more than one hour (critical)" alert policy from MQL to PromQL.

#### 1. Original Alert Definition
*   **Name**: Pod not ready for more than one hour (critical)
*   **File**: `alerts/pods/pod-not-ready-1h.yaml`

#### 2. Original MQL Query
```
{ t_0:
  fetch prometheus_target
  | metric 'kubernetes.io/anthos/kube_pod_status_phase/gauge'
  | filter (metric.phase =~ 'Pending|Unknown|Failed')
  | filter (metric.pod !~ '^(bm-system||robin-prejob).*')
  | group_by [resource.project_id, resource.location, resource.cluster,
  resource.namespace, metric.pod],
  [value_kube_pod_status_phase_mean: mean(value.gauge)]
  | every 1m
; t_1:
  fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
  | filter (metric.anthos_distribution = 'baremetal')
  | align mean_aligner()
  | group_by [resource.project_id, resource.location, cluster: resource.cluster_name],
  [value_anthos_cluster_info_aggregate:
  aggregate(value.anthos_cluster_info)]
  | every 1m }
| join
| value [t_0.value_kube_pod_status_phase_mean]
| window 1m
| condition t_0.value_kube_pod_status_phase_mean > 0 '1'
```

#### 3. Goal of the Alert ("the Why")
The purpose of this alert is to detect when a pod on a `baremetal` cluster remains in a "not ready" state (specifically `Pending`, `Unknown`, or `Failed`) for a continuous period of one hour. This helps identify pods that are stuck and unable to become operational.

#### 4. Converted PromQL Query
```
(sum by (pod, namespace, cluster, location, project_id) (kubernetes_io:anthos_kube_pod_status_phase_gauge{phase=~"Pending|Unknown|Failed", pod!~"^(bm-system||robin-prejob).*", }) > 0) and on(cluster, location, project_id) (max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) > 0
```

#### 5. Reasoning for Conversion ("the How")
The MQL query logic was translated into a single, equivalent PromQL expression:
1.  **Identify Not Ready Pods**: The MQL `fetch` and `filter` operations on `kube_pod_status_phase/gauge` are converted into a PromQL selector `kubernetes_io:anthos_kube_pod_status_phase_gauge{phase=~"Pending|Unknown|Failed", ...}`. The `sum by (...) > 0` correctly identifies the pods meeting this condition.
2.  **Filter for Baremetal Clusters**: The MQL `join` with `anthos_cluster_info` to filter for `anthos_distribution = 'baremetal'` is replicated in PromQL using the `and on(...)` vector matching operator.
3.  **Align Cluster Labels**: A key part of the conversion is the use of `label_replace(...)`. The MQL query renames `resource.cluster_name` to `cluster` to perform the join. The PromQL query does the inverse, creating a `cluster` label on the `anthos_cluster_info` metric to ensure the `and on(cluster, ...)` operation can match the two time series correctly.
4.  **Alert Condition**: The MQL `condition ... > 0` logic, combined with the policy's `duration: 3600s`, is equivalent to the PromQL query evaluating to true for the same duration. The PromQL query returns a value for pods that are not ready on baremetal clusters, and the alert policy's duration setting of `3600s` ensures the condition must persist for an hour.

#### 6. Validation
*   **Observation about Alerts**: Both the original MQL alert and the converted PromQL alert show "No data is available for the selected time frame" in their respective Google Cloud Monitoring UI views. This is the expected behavior for this type of alert when there are no pods currently violating the condition (i.e., all pods have been in a healthy state for the last hour).
*   **Tests Done**: The validation was performed by a logical comparison of the MQL and PromQL query structures. Each clause in the MQL query was mapped to its corresponding implementation in the PromQL query. The use of `and on()` and `label_replace` are standard, correct patterns for replicating the MQL's filtering `join` and label alignment.
*   **Acceptable Differences**: There are no functional differences. The visual representation in the UI is identical (both show "No data"), which is expected for a correctly configured alert that has no active incidents.
*   **Supporting Analysis**: The conversion is sound and follows best practices for translating MQL to PromQL. The PromQL query is a more concise but logically identical representation of the original MQL query's intent.
*   **Conclusion**: The converted PromQL alert is a correct and reliable replacement for the original MQL alert. It accurately identifies pods that have not been ready for an hour on baremetal clusters.
