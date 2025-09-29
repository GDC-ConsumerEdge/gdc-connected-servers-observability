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
