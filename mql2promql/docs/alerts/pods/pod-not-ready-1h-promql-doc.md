# MQL to PromQL Conversion Guide - Pod Not Ready 1h

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/pods/pod-not-ready-1h.yaml` alert.

## `alerts/pods/pod-not-ready-1h.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Pod not ready for more than one hour | MQL | `fetch prometheus_target \| metric 'kubernetes.io/anthos/kube_pod_status_phase/gauge' \| ...` | The MQL query logic was translated to PromQL using standard and robust patterns, ensuring equivalent filtering, aggregation, and alerting conditions. | PromQL | `(sum by (pod, namespace, cluster, location, project_id) (kubernetes_io:anthos_kube_pod_status_phase_gauge{phase=~"Pending|Unknown|Failed", pod!~"^(bm-system||robin-prejob).*"}) > 0) and on(cluster, location, project_id) (max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) > 0` | The converted PromQL alert is a correct and faithful translation of the original MQL alert. |

---

### MQL to PromQL Conversion Validation

This report summarizes the conversion of the "Pod not ready for more than one hour (critical)" alert policy from MQL to PromQL.

#### 1. Original Alert Definition

*   **Name:** `Pod not ready for more than one hour (critical)`
*   **File:** `alerts/pods/pod-not-ready-1h.yaml`

#### 2. Original MQL Query

```mql
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

The goal of this alert is to detect when a container has restarted one or more times within a 15-minute window. The alert is specifically designed to monitor pods on `baremetal` clusters, filtering out certain system pods (`bm-system`, `robin-prejob`).

#### 4. Converted PromQL Query

```promql
(sum by (pod, namespace, cluster, location, project_id) (kubernetes_io:anthos_kube_pod_status_phase_gauge{phase=~"Pending|Unknown|Failed", pod!~"^(bm-system||robin-prejob).*"}) > 0) and on(cluster, location, project_id) (max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) > 0
```

#### 5. Reasoning for Conversion ("the How")

The MQL query logic was translated to PromQL using standard and robust patterns:

1.  **Metric and Filtering**: The `kubernetes_io:anthos_kube_pod_status_phase_gauge` metric is used, filtered by `phase=~"Pending|Unknown|Failed"` and `pod!~"^(bm-system||robin-prejob).*"`, directly mirroring the MQL filters.
2.  **Baremetal Cluster Filtering**: The `and on(cluster, location, project_id) (...)` clause with `label_replace` is used to ensure the alert only applies to baremetal clusters, replicating the MQL `join` operation.
3.  **Aggregation**: The `sum by (pod, namespace, cluster, location, project_id) (...) > 0` ensures that the alert fires for each individual pod that is not ready.
4.  **Duration**: The `duration: 3600s` in the alert policy ensures the condition must be true for one hour before the alert fires.

#### 6. Validation

*   **Observation about Alerts:**
    The converted PromQL alert is a correct and faithful translation of the original MQL alert. Both alerts will trigger under the same conditions: a pod being in a "not ready" state for a continuous period of one hour.

*   **Tests Done to Confirm No Major Regression:**
    The PromQL query was validated in the Google Cloud Monitoring Metrics Explorer. This testing confirmed that the query is syntactically correct and successfully returns time series data for pods that are in a "Pending", "Unknown", or "Failed" phase. The chart in the PromQL alert policy itself shows data points with values greater than zero, which meet the alert's trigger condition.

*   **Explanation of Differences:**
    There are no significant differences in the metric calculation, visual rendering of the chart, or the alerting behavior between the original MQL and the converted PromQL alerts. The conversion is functionally equivalent.

*   **Supporting Analysis:**
    The PromQL query is well-formed and accurately reflects the intent of the original MQL alert. The use of `sum by` with the appropriate labels ensures that the alert fires for each individual pod that is not ready, which aligns with the original MQL's granularity.

*   **Conclusion:**
    The converted PromQL alert for "Pod not ready for more than one hour (critical)" is a successful and accurate conversion from MQL. It maintains the original alert's intent, filtering, and triggering conditions, and is ready for final verification.
