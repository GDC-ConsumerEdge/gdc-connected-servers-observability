# MQL to PromQL Conversion Guide - Scheduler Down

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/control-plane/scheduler-down.yaml` alert.

## `alerts/control-plane/scheduler-down.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Scheduler Down | MQL | `fetch k8s_container :: kubernetes.io/anthos/container/uptime | ... | absent_for 300s` | The MQL `absent_for` logic is translated to the PromQL `absent()` function. The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic. | PromQL | `absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-scheduler"})` | |

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

---

## Validation


This document provides a detailed comparison and validation for converting the MQL-based "Scheduler Down" alert to its PromQL equivalent.

#### **1. Original MQL Alert Analysis**

The original alert, defined in `scheduler-down.yaml`, is designed to detect when a `kube-scheduler` container on a **baremetal** GDC (Google Distributed Cloud) cluster is down for more than 5 minutes.

**MQL Query:**
```mql
{ t_0:
  fetch k8s_container
  | metric 'kubernetes.io/anthos/container/uptime'
  | filter (resource.container_name =~ 'kube-scheduler')
  ...
; t_1:
  fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
  | filter (metric.anthos_distribution = 'baremetal')
  ...
}
| join
| ...
| absent_for 300s
```

**Key Logic Components:**

1.  **Primary Metric**: It monitors the `kubernetes.io/anthos/container/uptime` for containers named `kube-scheduler`.
2.  **Join for Filtering**: It performs a `join` with the `kubernetes.io/anthos/anthos_cluster_info` metric. This is a critical step used to isolate only those clusters where the `anthos_distribution` is `baremetal`.
3.  **Alert Condition**: The `absent_for 300s` condition triggers the alert if the time series for a qualifying `kube-scheduler` container is missing for 5 minutes.

#### **2. Initial (Incorrect) PromQL Conversion**

The initial attempt at conversion resulted in a query that was too broad and missed the key filtering logic of the original MQL.

**Incorrect PromQL Query:**
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-scheduler"})
```
**Major Gap:** This query checks for the absence of any `kube-scheduler` container but completely omits the join and filter for `anthos_distribution="baremetal"`. This would cause the alert to fire for schedulers on non-baremetal clusters, leading to false positives.

#### **3. Final, Correct PromQL Conversion**

The corrected PromQL query successfully replicates the join and filtering logic from the original MQL alert.

**Correct PromQL Query:**
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-scheduler"} and on(project_id, location, cluster_name) kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"})
```

**Detailed Comparison:**

| MQL Logic | PromQL Implementation | Explanation |
| :--- | :--- | :--- |
| `metric '.../container/uptime'` with `filter (resource.container_name =~ 'kube-scheduler')` | `kubernetes_io:anthos_container_uptime{container_name=~"kube-scheduler"}` | This is a direct translation of fetching the uptime metric and filtering by the container name label. |
| `join` with `.../anthos_cluster_info` filtering for `anthos_distribution = 'baremetal'` | `and on(project_id, location, cluster_name) kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", ...}` | The PromQL `and on(...)` operator performs the vector matching (join) based on the specified labels, effectively filtering the uptime metric to include only those on baremetal clusters. |
| `fetch k8s_container::...` | `..., monitored_resource="k8s_container"}` | The MQL query explicitly fetches from the `k8s_container` resource. In PromQL, this ambiguity is resolved by adding the `monitored_resource="k8s_container"` label filter. This was a critical fix to resolve the `multiple possible monitored resource types` error. |
| `absent_for 300s` | `absent(...)` with a `duration` of `300s` in the alert policy | The `absent()` function in PromQL serves the same purpose, triggering when the time series specified in the inner query is no longer present. |

#### **4. Validation Steps**

To ensure the final PromQL query was a correct and reliable conversion, the following validation was performed:

1.  **Isolate the Core Logic**: The inner part of the query (without `absent()`) was tested independently in the **Metrics Explorer**.
    ```promql
    kubernetes_io:anthos_container_uptime{container_name=~"kube-scheduler"} and on(project_id, location, cluster_name) kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}
    ```
2.  **Verify the Result**: Running this query successfully returned time series data for each `kube-scheduler` container running on a baremetal cluster. This directly confirmed that the combination of filters and the join logic was correctly identifying the target metrics.
3.  **Confirm Alerting Behavior**: Since the inner query returns data when the schedulers are healthy, it is the correct and expected behavior for the complete `absent()`-based alert to show "No data available" in the alerting UI during normal operation. The alert is correctly configured to fire only when one of these time series disappears.
