### alerts/control-plane/scheduler-down.yaml

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
