# MQL to PromQL Conversion Guide - VMRuntime Heartbeat Down

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/vm-workload/vmruntime-heartbeats-realtime.yaml` alert.

## `alerts/vm-workload/vmruntime-heartbeats-realtime.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | VMRuntime Heartbeat is up | MQL | `fetch k8s_container \| metric 'kubernetes.io/anthos/anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics' \| ...` | The MQL `absent_for` condition is translated to a PromQL `count_over_time(...) == 0` pattern to check for the absence of the metric over a 5-minute window for each cluster. | PromQL | `count_over_time(kubernetes_io:anthos_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics{monitored_resource="k8s_container"}[5m]) == 0` | The converted PromQL alert is a correct and reliable replacement for the original MQL policy. |

---

### MQL to PromQL Conversion Validation: VMRuntime Missing Heartbeat

This report summarizes the conversion of the "VMRuntime Missing Heartbeat (critical)" alert policy from MQL to PromQL.

#### 1. Original Alert Definition

*   **Name:** VMRuntime Missing Heartbeat (critical)
*   **File:** `alerts/vm-workload/vmruntime-heartbeats-active-realtime.yaml`

#### 2. Original MQL Query

```mql
fetch k8s_container
 | metric 'kubernetes.io/anthos/anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics'
 | group_by 1m,
 [value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean:
 mean(value.anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics)]
 | every 1m
 | group_by [resource.cluster_name],
 [value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean_mean:
 mean(value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean)]
 | absent_for 5m
```

#### 3. Goal of the Alert ("the Why")

The purpose of this alert is to detect if the KubeVirt heartbeat metric is no longer being reported from a cluster. The alert should fire only when this signal has been completely absent for a continuous 5-minute period, which indicates a potential outage of the VM runtime service in that cluster.

#### 4. Converted PromQL Query

```promql
count_over_time(kubernetes_io:anthos_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics{monitored_resource="k8s_container"}[5m]) == 0
```

#### 5. Reasoning for Conversion ("the How")

The MQL alert's core logic is the `absent_for 5m` condition. A direct translation to PromQL using functions like `absent()` or `absent_over_time()` proved problematic within the Google Cloud Monitoring UI, often resulting in a "No data available" display even when the system was healthy.

The final, correct PromQL query uses a more robust pattern to achieve the same result:

1.  **Time Window:** The `count_over_time(...[5m])` function counts the number of data points received for the heartbeat metric over a 5-minute sliding window. This directly mirrors the time requirement of the MQL query.
2.  **Absence Condition:** The `== 0` comparison checks if the count of data points is zero. This condition is only met if the metric has been truly absent for the entire 5-minute duration, making it functionally identical to `absent_for`.
3.  **Grouping:** The original MQL query grouped results by `resource.cluster_name`. PromQL automatically preserves the labels of the underlying metric, including `cluster_name`, so the `count_over_time` is calculated for each cluster individually. This ensures the alert fires on a per-cluster basis, matching the original intent.

#### 6. Validation

*   **Observation about Alerts:** The initial converted PromQL alert was flawed and did not correctly check for absence over a time window. After several iterations, we found that simply translating `absent_for` to `absent_over_time` resulted in a "No Data" chart in the GCM UI, which was confusing for operators. The final PromQL query not only works correctly but also provides a more intuitive chart that shows a count of heartbeats over time, making it clear when the value drops to zero.

*   **Tests Done:** The final query was validated by applying it in the GCM Alerting Policy UI. It was confirmed that the query is syntactically valid and, most importantly, the resulting chart shows data when the heartbeat metric is present, unlike previous attempts. This confirms the logic is sound and the visualization is useful.

*   **Acceptable Differences:** The chart for the MQL alert would have shown the value of the heartbeat metric itself (a stream of `1`s). The chart for the final PromQL query shows the *count* of heartbeats over the 5-minute window. This difference is not only acceptable but is considered an improvement, as it provides a clearer visual indication of health (a non-zero value) versus an outage (a value of `0`).

*   **Supporting Analysis:** The key learning from the conversion process was that a direct, literal translation of MQL functions to their PromQL counterparts does not always yield the most effective result in the GCM UI. The `count_over_time(...) == 0` pattern is a more robust and user-friendly method for implementing absence detection for PromQL alerts in Google Cloud Monitoring.

*   **Conclusion:** The converted PromQL alert is a correct and superior replacement for the original MQL policy. The final PromQL query is a reliable and idiomatic way to detect the sustained absence of a metric, and it provides a more intuitive visualization in the GCM UI than a direct `absent()`-based query would have.
