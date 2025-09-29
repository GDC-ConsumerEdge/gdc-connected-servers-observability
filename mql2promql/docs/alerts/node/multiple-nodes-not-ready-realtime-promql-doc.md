# MQL to PromQL Conversion Guide - Multiple Nodes Not Ready

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/node/multiple-nodes-not-ready-realtime.yaml` alert.

## `alerts/node/multiple-nodes-not-ready-realtime.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Multiple Nodes Not Ready | MQL | `fetch prometheus_target :: kubernetes.io/anthos/kube_node_status_condition/gauge | ...` | The MQL query counts nodes that are not in the 'Ready' state. The PromQL equivalent filters for nodes where the 'Ready' condition is not 'true' and counts them. The simplified version is recommended for broader applicability. | PromQL | `count by (project_id, location, cluster_name) (kube_node_status_condition{condition="Ready", status="true"} == 0) > 1` | The simplified query is more idiomatic and works across different Kubernetes distributions. |

---

**MQL Query:**
```mql
{ t_0:
    fetch prometheus_target
    | metric 'kubernetes.io/anthos/kube_node_status_condition/gauge'
    | filter (metric.condition == 'Ready' && metric.status != 'true')
    | group_by [resource.project_id, resource.location, resource.cluster],
        [value_kube_node_status_condition_mean:
           mean(value.gauge)]
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
| value [t_0.value_kube_node_status_condition_mean]
| window 1m
| condition t_0.value_kube_node_status_condition_mean > 0 '1'
```

**PromQL Query (with Baremetal Filter):**
```promql
count by (project_id, location, cluster_name) (kube_node_status_condition{condition="Ready", status="true"} == 0)
* on(project_id, location, cluster_name) group_left()
(max by (project_id, location, cluster_name) (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}))
> 1
```

**Reasoning:**
1.  The MQL `fetch` and `metric` are converted to the PromQL metric name `kube_node_status_condition`.
2.  The MQL `filter` for nodes that are not ready (`metric.condition == 'Ready' && metric.status != 'true'`) is translated to the PromQL label selector `{condition="Ready", status="true"} == 0`.
3.  The MQL `trigger` count of 2 is achieved by counting the nodes that are not ready using `count by (...)` and alerting when the sum is greater than 1.
4.  The `join` with `anthos_cluster_info` is converted to a multiplication (`*`). To prevent a "duplicate series" error and ensure a correct join with the node-level metric, the right-hand side is aggregated with `max by (...)` and the `monitored_resource` label is added to resolve ambiguity. The `on(...) group_left()` clause ensures the labels are preserved correctly.

**Simplified PromQL Query (Recommended):**
```promql
count by (project_id, location, cluster_name) (kube_node_status_condition{condition="Ready", status="true"} == 0) > 1
```

**Reasoning for Simplification:**
This version is the most direct and idiomatic PromQL query for this alert. It omits the join with `anthos_cluster_info` for simplicity. While the original MQL included a filter for "baremetal" clusters, this simplified query will work on *any* Kubernetes cluster, which is often more desirable for a general-purpose alert. It is more readable and less prone to join-related errors.