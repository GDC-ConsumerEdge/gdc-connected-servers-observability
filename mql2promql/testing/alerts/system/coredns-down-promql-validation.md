### MQL to PromQL Conversion Validation: CoreDNS Down

This report summarizes the conversion of the "CoreDNS down (critical)" alert policy from MQL to PromQL.

#### 1. Original Alert Definition

*   **Name**: CoreDNS down (critical)
*   **File**: `alerts/system/coredns-down.yaml`

#### 2. Original MQL Query
```mql
{ t_0:
  fetch k8s_container
  | metric 'kubernetes.io/anthos/container/uptime'
  | filter (resource.container_name =~ 'coredns')
  | align mean_aligner()
  | group_by 1m, [value_up_mean: mean(value.uptime)]
  | every 1m
  | group_by [resource.project_id, resource.location, resource.cluster_name],
    [value_up_mean_aggregate: aggregate(value_up_mean)]
  ; t_1:
  fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
  | filter (metric.anthos_distribution = 'baremetal')
  | align mean_aligner()
  | group_by [resource.project_id, resource.location, resource.cluster_name],
    [value_anthos_cluster_info_aggregate:
      aggregate(value.anthos_cluster_info)]
  | every 1m }
| join
| value [t_0.value_up_mean_aggregate]
| window 1m
| absent_for 300s
```
(Source: `alerts/system/coredns-down.yaml`)

#### 3. Goal of the Alert ("the Why")

The goal of the alert is to detect when the CoreDNS service is down on a bare-metal cluster. It identifies clusters where the CoreDNS uptime metric has been absent for a continuous period of 5 minutes, allowing for a timely response to potential DNS resolution failures within a cluster.

#### 4. Converted PromQL Query
```promql
(max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) unless (avg by (cluster, location, project_id) (kubernetes_io:anthos_container_uptime{container_name=~"coredns", monitored_resource="k8s_container"}))
```

#### 5. Reasoning for Conversion ("the How")

The original MQL query was translated to PromQL by replicating its per-cluster absence detection logic. Initial attempts to use `absent(... and ...)` were incorrect because they collapsed the output into a single time series, losing the critical per-cluster granularity. The final, correct query uses the `unless` operator to perform a set difference, which is the idiomatic PromQL approach for this scenario.

1.  **Identify Bare-metal Clusters**: The `max by (...) (label_replace(kubernetes_io:anthos_anthos_cluster_info{...}))` part of the query generates a list of all clusters that are designated as "baremetal". The `label_replace` is necessary to align the `cluster_name` label from this metric with the `cluster` label used by the uptime metric.
2.  **Identify Running CoreDNS Instances**: The `avg by (...) (kubernetes_io:anthos_container_uptime{...})` part generates a list of all clusters where CoreDNS is currently reporting uptime data.
3.  **Find the Difference**: The `unless` operator takes the list of all bare-metal clusters (left side) and removes the clusters where CoreDNS is reporting uptime (right side). The result is a list of exactly those bare-metal clusters where CoreDNS is down.
4.  **Alert Condition**: The alert policy's `duration` of 300s is then applied to this result, ensuring an alert only fires for a cluster if it remains in this "down" state for 5 minutes.

#### 6. Validation

*   **Observation about Alerts**: The original MQL alert correctly showed multiple open incidents, one for each cluster where CoreDNS was down. The initial, incorrect PromQL conversions failed to replicate this behavior, either showing "No data" or aggregating all clusters into a single result. The final PromQL query using `unless` successfully generates a distinct time series for each affected cluster, mirroring the MQL's per-cluster alerting behavior.

*   **Tests Done**: Validation was an iterative process. We confirmed that the `absent()` function was not suitable for this per-cluster logic. We then tested the `unless` operator and verified in the GCM UI that it produced the desired list of failing clusters, which was the key to a successful conversion.

*   **Acceptable Differences**: The primary difference is in the chart visualization. The MQL alert chart shows the CoreDNS uptime when present. The PromQL alert chart shows a list of clusters for which the uptime is *absent*. This is an expected and acceptable difference, as the PromQL chart is showing the alert condition itself rather than the underlying metric.

*   **Supporting Analysis**: The crucial insight was that a per-cluster absence alert in MQL (`absent_for` after a `group_by`) is best translated to a set operation in PromQL (`unless`) rather than a simple `absent()` function. This preserves the per-cluster context required for granular alerting.

*   **Conclusion**: The converted PromQL alert policy is a correct and functionally equivalent replacement for the original MQL policy. It accurately identifies and alerts on individual bare-metal clusters where the CoreDNS service is down, fulfilling the original intent with a more robust PromQL query structure.
