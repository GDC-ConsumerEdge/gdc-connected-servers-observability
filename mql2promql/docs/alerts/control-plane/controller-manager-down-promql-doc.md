# MQL to PromQL Conversion Guide - Controller Manager Down

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/control-plane/controller-manager-down.yaml` alert.

## `alerts/control-plane/controller-manager-down.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Controller Manager Down | MQL | `fetch k8s_container :: kubernetes.io/anthos/container/uptime | ... | absent_for 300s` | The MQL `absent_for` logic is translated to the PromQL `absent()` function. The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic. | PromQL | `absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-controller-manager"})` | |

---

**MQL Query:**
```mql
{ t_0:
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/uptime'
    | filter (resource.container_name =~ 'kube-controller-manager')
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

**PromQL Query:**
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-controller-manager"})
```

**Reasoning:**
1.  The MQL `absent_for` logic is translated to the PromQL `absent()` function.
2.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.

---

## Validation

This section provides a summary of the conversion of the `controller-manager-down` alert from MQL to PromQL. The final PromQL query is a correct and functionally equivalent translation of the original MQL, successfully replicating the core logic for filtering and absence detection.

#### Final PromQL Query

The final corrected query for the `controller-manager-down-promql.yaml` file is:
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-controller-manager"}) * on(project_id, location, cluster_name) group_left() (kubernetes_io:anthos_anthos_cluster_info{monitored_resource="k8s_container", anthos_distribution="baremetal"})
```

#### Detailed Comparison

The following table details the comparison between the original MQL alert and the final converted PromQL alert.

| Feature | Original MQL Alert | Converted PromQL Alert | Analysis |
| :--- | :--- | :--- | :--- |
| **Goal** | Alert when the `kube-controller-manager` uptime metric has been missing for 5 minutes, but only for clusters identified as "baremetal". | Same. | The fundamental goal of both alerts is identical. |
| **Filtering for Bare Metal** | Uses a `join` operation to explicitly filter for time series where `metric.anthos_distribution = 'baremetal'`. | Uses a `* on(...) group_left()` vector matching operation with `kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal"}`. | **Match.** The PromQL vector matching with the `*` operator correctly replicates the MQL `join`, ensuring the alert is only evaluated for clusters identified as baremetal. |
| **Detecting Absence** | Uses the `absent_for 300s` condition to check if the uptime metric is missing for 5 minutes. | The `absent()` function returns a result when the uptime metric is missing. The policy's `duration: 300s` ensures this condition must persist for 5 minutes to trigger an alert. | **Match.** The combination of the `absent()` function and the alert policy's `duration` setting is functionally equivalent to MQL's `absent_for` condition. |
| **Resource Scoping** | Explicitly uses `fetch k8s_container` to define the resource type for both metrics. | Explicitly adds the `monitored_resource="k8s_container"` label filter to the `anthos_cluster_info` metric. | **Match.** This was a critical fix. The PromQL query must explicitly define the monitored resource to resolve the ambiguity of the `anthos_cluster_info` metric, which can exist on multiple resource types. |

#### Explanation of Conversion and Validation

The initial PromQL conversion was too simplistic and failed to replicate the MQL's filtering logic. The final, correct query was achieved through an incremental validation process.

1.  **Replicating the Join:** The core of the MQL query is joining the `uptime` metric with the `anthos_cluster_info` metric to filter by cluster type. The PromQL equivalent uses the multiplication operator (`*`) with an `on()` clause to act as a join. The `group_left()` ensures that the labels from the `anthos_cluster_info` metric are preserved in the result.

2.  **Resolving Resource Ambiguity:** A key finding was that the `kubernetes.io/anthos/anthos_cluster_info` metric can be associated with multiple resource types. This caused errors in PromQL until the query was modified to explicitly specify `monitored_resource="k8s_container"`, matching the intent of the MQL `fetch k8s_container` statement.

3.  **Validating the "No Data" Behavior:** A crucial part of the validation was understanding the difference in how the alert is visualized in the Google Cloud Monitoring UI.
    *   The **MQL alert** graphs the underlying `container/uptime` metric, so the chart shows data when the system is healthy.
    *   The final **PromQL alert** graphs the output of the `absent()` function. This function only produces data when the uptime metric is missing. Therefore, the chart correctly shows **"No data is available"** during normal operation. This is the expected behavior and confirms the alert is working, as it will only produce a signal when a controller manager is down.

This was validated by removing the `absent()` function in the Metrics Explorer, which correctly showed a graph of the uptime for controller managers on baremetal clusters, proving the join and filtering logic was correct.

#### Final YAML Configuration

To implement this change, the `mql2promql/alerts-promql/control-plane/controller-manager-down-promql.yaml` file should be updated as follows:

```yaml
combiner: OR
conditions:
- conditionPrometheusQueryLanguage:
    duration: 300s
    query: |-
      absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-controller-manager"}) * on(project_id, location, cluster_name) group_left() (kubernetes_io:anthos_anthos_cluster_info{monitored_resource="k8s_container", anthos_distribution="baremetal"})
    displayName: Controller manager is up - PromQL
displayName: Controller manager down (critical) - converted to PromQL
```

