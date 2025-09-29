# MQL to PromQL Conversion Guide - GDC VM Distribution 

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `gdc-vm-distribution.json` dashboard and the Testing Results

## `dashboards/gdc-vm-distribution.json`

This section details the conversion of the "VMs" and "Robin Master" widgets from the "GDC - VM Distribution" dashboard. The goal was to translate complex, multi-stage MQL queries into functional PromQL equivalents that correctly group running pods by their respective names for each node.

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| :---- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| VMs | Node 1 | MQL | `{ t_0: fetch ... \| metric '...kube_pod_status_phase/gauge' ...; t_1: fetch ... \| metric '...kube_pod_info/gauge' ... } \| join \| ... \| group_by [metric.created_by_name]` | The conversion joins pod status with pod info to identify running VMs, then aggregates them by VM name (`created_by_name`). Using the `AND` operator was critical for correct label propagation from the `pod_info` metric. | PromQL | `sum by (created_by_name) (kubernetes_io:anthos_kube_pod_info_gauge{...} AND on(pod) kubernetes_io:anthos_kube_pod_status_phase_gauge{...})` | The final query provides an instantaneous count. This differs from the original's 5-minute average but correctly solves the primary grouping requirement. |
| Robin Master | Node 1 | MQL | `{ t_0: fetch ... \| metric '...kube_pod_status_phase/gauge' ...; t_1: fetch ... \| metric '...kube_pod_info/gauge' ... } \| join \| ... \| group_by [metric.pod]` | The conversion joins pod status with pod info to identify running `robin-master` pods. A simple multiplication (`*`) is sufficient here because the grouping key (`pod`) exists on both metrics. | PromQL | `sum by (pod) (kubernetes_io:anthos_kube_pod_status_phase_gauge{...} * on(pod) kubernetes_io:anthos_kube_pod_info_gauge{...})` |  |

#### Original MQL Query (VMs, Node 1)

The original MQL query involves a `join` between `kube_pod_status_phase` and `kube_pod_info` and multiple `group_by` operations to finally aggregate the count of running VMs by their `created_by_name`.

```mql
{ t_0 : fetch prometheus_target
 | metric 'kubernetes.io/anthos/kube_pod_status_phase/gauge'
 | filter resource.cluster='${cluster_name.value}'
 | filter
 metric.phase == 'Running' && (metric.pod =~ '(virt-launcher).*')
 | group_by 1m, [value_gauge_mean: mean(value.gauge)]
 | every 1m
 | group_by [metric.phase, metric.pod],
 [value_gauge_mean_aggregate: min(value_gauge_mean)];
t_1: fetch prometheus_target
 | metric 'kubernetes.io/anthos/kube_pod_info/gauge'
 | filter resource.cluster = "${cluster_name.value}"
 | filter metric.pod =~ '(virt-launcher).*'
 | filter metric.node =~ '.*01.ba.l.google.com$$'
 }
| join
| filter t_0.value_gauge_mean_aggregate > 0
| group_by 5m, [value_gauge_mean: mean(value.gauge)]
| every 5m
| group_by [metric.created_by_name]
```

#### Final PromQL Query (VMs, Node 1)

The final PromQL query provides an instantaneous count of running VMs, grouped by `created_by_name`.

```promql
sum by (created_by_name) (kubernetes_io:anthos_kube_pod_info_gauge{pod=~"(virt-launcher).*", node=~".*01.ba.l.google.com$", cluster="${cluster_name.value}"} AND on(pod) kubernetes_io:anthos_kube_pod_status_phase_gauge{phase="Running", pod=~"(virt-launcher).*", cluster="${cluster_name.value}"})
```

#### Final PromQL Query (Robin Master, Node 1)

The final PromQL query provides an instantaneous count of running `robin-master` pods, grouped by the pod name.

```promql
sum by (pod) (kubernetes_io:anthos_kube_pod_status_phase_gauge{phase="Running", pod=~"(robin-master).*", cluster="${cluster_name.value}"} * on(pod) kubernetes_io:anthos_kube_pod_info_gauge{pod=~"(robin-master).*", node=~".*01.ba.l.google.com$", cluster="${cluster_name.value}"})
```

#### Reasoning for the Conversion

The conversion process revealed several key principles for translating these MQL queries to PromQL:

1.  **Label Translation is Key:** The most critical issue was translating the MQL resource label `resource.cluster`. The correct PromQL equivalent is the `cluster` label, not `cluster_name`. This was the primary reason the initial queries returned "No data".

2.  **Choosing the Right Join Operator:**
    *   For the **VMs** widgets, the goal was to group by the `created_by_name` label, which only exists on the `pod_info` metric. The `AND` operator was the correct choice. It filters the series from the left-hand side (`pod_info`) based on matches on the right (`status_phase`), preserving the necessary `created_by_name` label for the final aggregation.
    *   For the **Robin Master** widgets, a simple multiplication (`*`) was sufficient. Since the grouping key (`pod`) exists on both metrics and is the joining key, the operator correctly combines the series.

3.  **Final Aggregation:** The `sum by (...)` wrapper correctly aggregates the results from the join operation, providing the per-VM or per-pod breakdown seen in the original dashboard.

### Final Comparison Summary

Overall, the conversion has been successful. The most critical issues that we worked on together have been resolved:
*   **No Data Issue:** The dashboard is no longer empty. The widgets are populated with data, as the queries now correctly use the `cluster` label instead of `cluster_name`.
*   **Grouping Issue:** The "VMs" widgets now correctly show a breakdown of individual VMs by name (`alpha-vm`, `linux-vm`, etc.) in the legend, matching the behavior of the original MQL dashboard. This was fixed by using the `AND` operator to ensure the `created_by_name` label was propagated correctly.

There is one remaining known difference between the two dashboards, which is a direct result of our last change to remove the `avg_over_time` function.

#### Known Difference: Instantaneous vs. 5-Minute Averaged Data

The only remaining discrepancy is the time alignment of the data.

*   **Original MQL Dashboard:** The charts for both the "VMs" and "Robin Master" widgets display data that has been aligned to 5-minute intervals and averaged. This is because the original MQL queries contain a `group_by 5m, [value_gauge_mean: mean(value.gauge)]` clause. This results in a smoother-looking graph that represents the average number of running pods over each 5-minute window.

*   **Current PromQL Dashboard:** The charts now display an *instantaneous* count of running pods. Because we reverted the change that used `avg_over_time`, the queries now show the exact state at each point in time. This will result in a more "jagged" or "stepped" graph that reacts immediately to pods starting or stopping.

**This is not a regression or a bug**, but rather a known trade-off. While the `avg_over_time` function would have perfectly replicated the original dashboard's smoothing, it was causing issues in your environment. The current version is a functional and accurate representation of the instantaneous state, which is a standard and valid approach for this type of monitoring.

### Conclusion

The converted PromQL dashboard is now in a stable and correct state. It successfully addresses the critical requirements of showing data and grouping it by the individual VM names. The only remaining difference is the lack of 5-minute data smoothing, which was intentionally removed to resolve a technical issue.

There are no other major discrepancies or gaps. The conversion can be considered complete and successful.

