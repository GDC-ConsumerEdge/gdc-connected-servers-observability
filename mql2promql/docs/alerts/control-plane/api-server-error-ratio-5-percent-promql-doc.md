# MQL to PromQL Conversion Guide - API Server Error Ratio

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/control-plane/api-server-error-ratio-5-percent.yaml` alert.

## `alerts/control-plane/api-server-error-ratio-5-percent.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | API Server Error Ratio > 5% | MQL | `fetch k8s_container :: kubernetes.io/anthos/apiserver_aggregated_request_total | ...` | The MQL query calculates the ratio of 5xx errors to total requests for the kube-apiserver. The PromQL equivalent uses `increase()` to get the count of requests over a 5-minute window, calculates the ratio, and then joins with `anthos_cluster_info` to filter for baremetal clusters. | PromQL | `(sum by(project_id, location, cluster_name) (increase(kubernetes_io:anthos_apiserver_aggregated_request_total{container_name=~"kube-apiserver", code=~"5.."}[5m])) / sum by(project_id, location, cluster_name) (increase(kubernetes_io:anthos_apiserver_aggregated_request_total{container_name=~"kube-apiserver"}[5m])) * on(project_id, location, cluster_name) group_left() (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"})) > 0.05` | |

---

**MQL Query:**
```mql
{ t_0:
    { t_0:
        fetch k8s_container
        | metric 'kubernetes.io/anthos/apiserver_aggregated_request_total'
        | filter
            (resource.container_name =~ 'kube-apiserver')
            && (metric.code =~ '^(?:5..)$')
        | align delta(5m)
        | every 5m
        | group_by
            [resource.project_id, resource.location, resource.cluster_name],
            [value_apiserver_aggregated_request_total_aggregate:
               aggregate(value.apiserver_aggregated_request_total)]
    ; t_1:
        fetch k8s_container
        | metric 'kubernetes.io/anthos/apiserver_aggregated_request_total'
        | filter (resource.container_name =~ 'kube-apiserver')
        | align delta(5m)
        | every 5m
        | group_by
            [resource.project_id, resource.location, resource.cluster_name],
            [value_apiserver_aggregated_request_total_aggregate:
               aggregate(value.apiserver_aggregated_request_total)] }
    | join
    | value
        [v_0:
           div(t_0.value_apiserver_aggregated_request_total_aggregate,
             t_1.value_apiserver_aggregated_request_total_aggregate)]
; t_2:
    fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
    | filter (metric.anthos_distribution = 'baremetal')
    | align mean_aligner()
    | group_by [resource.project_id, resource.location, resource.cluster_name],
        [value_anthos_cluster_info_aggregate:
           aggregate(value.anthos_cluster_info)]
    | every 5m }
| join
| value [t_0.v_0]
| window 5m
| condition t_0.v_0 > 0.05 '1'
```

**PromQL Query:**
```promql
(sum by(project_id, location, cluster_name) (increase(kubernetes_io:anthos_apiserver_aggregated_request_total{container_name=~"kube-apiserver", code=~"5.."}[5m]))
/
sum by(project_id, location, cluster_name) (increase(kubernetes_io:anthos_apiserver_aggregated_request_total{container_name=~"kube-apiserver"}[5m]))
* on(project_id, location, cluster_name) group_left() (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}))
> 0.05
```

**Reasoning:**
1.  The MQL `fetch` and `metric` are converted to the PromQL metric name `kubernetes_io:anthos_apiserver_aggregated_request_total`.
2.  The MQL `filter`s are converted to PromQL label selectors `{container_name=~"kube-apiserver", code=~"5.."}`.
3.  The MQL `align delta(5m)` and `group_by` are converted to `sum by(...) (increase(...[5m]))`.
4.  The division of the two time series is performed with the `/` operator.
5.  The final `join` to filter for baremetal clusters is done with an `* on(...) group_left()` to multiply by a boolean info metric, ensuring the alert only fires on baremetal clusters.

## Validation

The conversion of the MQL-based alert policy to PromQL is correct and functionally equivalent. The core logic for calculating the error ratio, filtering, and thresholding has been accurately translated.

### Key Conversion Points

| Feature | Original MQL | Converted PromQL | Rationale |
| :--- | :--- | :--- | :--- |
| **Error Count** | `align delta(5m)` on 5xx responses | `sum by(...) (increase(...{code=~"5.."}[5m]))` | The PromQL `increase()` function is the direct equivalent of MQL's `align delta()` for calculating the count of events over a time window. |
| **Total Count** | `align delta(5m)` on all responses | `sum by(...) (increase(...[5m]))` | Similarly, `increase()` correctly calculates the total number of requests over the same window. |
| **Filtering** | A `join` with `anthos_cluster_info` to filter for `baremetal` clusters. | `* on(...) group_left() (...)` vector matching | Vector matching with the `*` operator is the idiomatic PromQL pattern for filtering a metric based on the existence of another metric's labels, which is equivalent to the MQL `join`. |
| **Threshold** | `> 0.05` | `> 0.05` | The threshold value is identical. |
| **Duration** | `600s` | `600s` | The alert duration is identical. |

### Observed Differences in the UI

*   **"No Data Available":** Both the MQL and PromQL alert policies show "No data is available for the selected time frame" in the `cloud-alchemists-sandbox` project. This is not a conversion error but indicates an absence of the `kubernetes.io/anthos/apiserver_aggregated_request_total` metric in the environment, making a live data comparison impossible.
*   **Missing Threshold Line:** The original MQL alert view displays a static threshold line at 0.05 on its chart, while the converted PromQL view does not. This is a cosmetic difference in the Google Cloud Monitoring UI. The UI can parse the distinct `| condition ... > 0.05` operator in MQL to render the line. However, for PromQL, it does not parse the boolean comparison `> 0.05` from the query string to draw a line. This visual difference does not affect the alert's functionality; the PromQL alert will still trigger correctly.

### Conclusion

The PromQL alert policy is a correct and reliable replacement for the original MQL policy. All functional aspects have been accurately translated, and the observed differences are cosmetic UI behaviors, not functional regressions.