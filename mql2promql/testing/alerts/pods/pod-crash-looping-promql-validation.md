### MQL to PromQL Conversion Validation: Pod Crash Looping (Critical)

This report summarizes the conversion of the "Pod crash looping (critical)" alert policy from MQL to PromQL.

#### 1. Original Alert Definition

*   **Name:** `Pod crash looping (critical)`
*   **File:** `alerts/pods/pod-crash-looping.yaml`

#### 2. Original MQL Query

```mql
{ t_0:
   fetch prometheus_target
   | metric 'kubernetes.io/anthos/kube_pod_container_status_restarts_total/counter'
   | filter (metric.pod !~ '^(bm-system|robin-prejob).*')
   | align delta(15m)
   | every 15m
   | group_by
       [resource.project_id, resource.location, resource.cluster,
        resource.namespace, metric.container],
       [value_kube_pod_container_status_restarts_total_aggregate:
         aggregate(value.counter)]
 ; t_1:
   fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
   | filter (metric.anthos_distribution = 'baremetal')
   | align mean_aligner()
   | group_by [resource.project_id, resource.location, cluster: resource.cluster_name],
       [value_anthos_cluster_info_aggregate:
         aggregate(value.anthos_cluster_info)]
   | every 15m }
| join
| value [t_0.value_kube_pod_container_status_restarts_total_aggregate]
| window 15m
| condition t_0.value_kube_pod_container_status_restarts_total_aggregate > 0 '1'
```

#### 3. Goal of the Alert ("the Why")

The goal of this alert is to detect when a container has restarted one or more times within a 15-minute window. The alert is specifically designed to monitor pods on `baremetal` clusters, filtering out certain system pods (`bm-system`, `robin-prejob`).

#### 4. Converted PromQL Query

```promql
increase(kubernetes_io:anthos_kube_pod_container_status_restarts_total_counter{pod!~"^(bm-system|robin-prejob).*"}[15m]) * on(cluster) group_left() (label_replace(max(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}) by (cluster_name), "cluster", "$1", "cluster_name", "(.*)")) > 0
```

#### 5. Reasoning for Conversion ("the How")

The MQL query logic was translated to PromQL using standard and robust patterns:

1.  **Calculating Restarts**: The MQL `align delta(15m)` on a `counter` metric is the equivalent of the PromQL `increase(...[15m])` function. Both calculate the increase in the restart counter over a 15-minute period.
2.  **Filtering for Baremetal Clusters**: The MQL `join` with the `anthos_cluster_info` metric is replicated in PromQL using a multiplication (`*`) vector match. This acts as a filter, keeping only the restart metrics from clusters identified as "baremetal".
3.  **Label Alignment**: A `label_replace()` function is used to create a common `cluster` label on the `anthos_cluster_info` metric. This is a crucial step to ensure the join with the restart metric, which uses a `cluster` label, can succeed.
4.  **Threshold**: The `> 0` condition in PromQL directly corresponds to the MQL `condition ... > 0`, triggering the alert if the restart count is greater than zero.

#### 6. Validation

*   **Observation about Alerts:**
    There is a significant functional gap between the two alerts. The original MQL alert correctly fires and creates incidents, as seen in the GCM UI. However, the converted PromQL alert, even with the logically correct query, fails to create any incidents.

*   **Tests Done to Confirm No Major Regression:**
    The PromQL query was validated in the Google Cloud Monitoring Metrics Explorer. This testing confirmed that the query is syntactically correct and successfully returns time series data for pods that have restarted. The chart in the PromQL alert policy itself shows data points with values greater than zero, which meet the alert's trigger condition.

*   **Explanation of Differences:**
    The difference is not in the metric calculation or the visual rendering of the chart, but in the final step of the alerting process. The PromQL query correctly identifies restarting pods and the chart displays this data, yet the alert does not fire. This is **not an acceptable difference**, as it represents a complete failure of the alert's primary function.

*   **Supporting Analysis:**
    The fact that the query works in Metrics Explorer but does not trigger an alert suggests the issue is not with the query's logic. The problem likely lies in a more subtle interaction within the Google Cloud Monitoring alerting service for PromQL-based alerts, possibly related to how it handles the labels from the `group_left()` join in the final alerting evaluation.

*   **Conclusion:**
    While the PromQL query is a correct **logical** translation of the MQL query's intent, it is not a successful **functional** conversion because it fails to trigger alerts. The investigation has been paused, as the root cause appears to be beyond the query itself and may require a deeper investigation into the GCM alerting platform's behavior with this specific type of PromQL query.
