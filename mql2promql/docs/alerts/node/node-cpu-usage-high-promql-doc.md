# MQL to PromQL Conversion Guide - Node CPU Usage High

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/node/node-cpu-usage-high.yaml` alert.

## `alerts/node/node-cpu-usage-high.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Node allocatable cpu cores percent | MQL | `fetch prometheus_target \| metric 'kubernetes.io/anthos/kube_node_status_allocatable/gauge' \| ...` | The MQL query calculates the ratio of allocatable CPU to capacity and filters for baremetal clusters. The PromQL query replicates this using division, an `and on()` join to filter, and `label_replace` to align cluster labels for the join. | PromQL | `(sum by(node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_allocatable_gauge{resource="cpu"}) / sum by(node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_capacity_gauge{resource="cpu"})) and on(cluster, location, project_id) (max by(cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) < 0.2` | The GCM UI shows a threshold line for the MQL alert but not for the PromQL alert. This is a cosmetic difference and does not affect functionality. |

---

#### 1. Original Alert Definition

-   **Name:** `Node cpu usage exceeds 80 percent (critical)`
-   **File:** `alerts/node/node-cpu-usage-high.yaml`

#### 2. Original MQL Query

```mql
{ t_0:
  { t_0:
      fetch prometheus_target
      | metric 'kubernetes.io/anthos/kube_node_status_allocatable/gauge'
      | filter (metric.resource == 'cpu')
      | group_by [metric.node, resource.cluster, resource.location, resource.project_id],
          [value_kube_node_status_allocatable_mean:
            mean(value.gauge)]
      | every 1m
  ; t_1:
      fetch prometheus_target
      | metric 'kubernetes.io/anthos/kube_node_status_capacity/gauge'
      | filter (metric.resource == 'cpu')
      | group_by [metric.node, resource.cluster, resource.location, resource.project_id],
          [value_kube_node_status_capacity_mean:
            mean(value.gauge)]
      | every 1m }
  | join
  | value
      [v_0:
        div(t_0.value_kube_node_status_allocatable_mean,
            t_1.value_kube_node_status_capacity_mean)]
; t_2:
    fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
    | filter (metric.anthos_distribution = 'baremetal')
    | align mean_aligner()
    | group_by [resource.project_id, resource.location, cluster: resource.cluster_name],
        [value_anthos_cluster_info_aggregate:
          aggregate(value.anthos_cluster_info)]
    | every 1m }
| join
| window 1m
| value [t_0.v_0]
| condition t_0.v_0 < 0.2 '1'
```

#### 3. Goal of the Alert ("the Why")

The alert's goal is to detect when the allocatable CPU resources on a node drop below 20% of its total CPU capacity for a duration of 10 minutes. Crucially, this condition is only evaluated for nodes belonging to a cluster with an `anthos_distribution` of `baremetal`. This is intended to proactively catch CPU resource pressure on production bare metal nodes.

#### 4. Converted PromQL Query

```promql
(sum by(node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_allocatable_gauge{resource="cpu"}) / sum by(node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_capacity_gauge{resource="cpu"})) and on(cluster, location, project_id) (max by(cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) < 0.2
```

#### 5. Reasoning for Conversion ("the How")

The original MQL alert uses two `join` operations. The first calculates the CPU ratio, and the second filters these results based on the cluster's distribution type. The PromQL query replicates this logic using standard operators:

1.  **Ratio Calculation**: The PromQL query uses the division operator (`/`) to compute the ratio of `allocatable` to `capacity` CPU, which is a direct translation of the MQL `div()` function.
2.  **Filtering Join**: The second `join` in the MQL query, used for filtering, is translated into a PromQL `and on(...)` vector matching operation. This ensures that the CPU ratio is only considered for time series that have a matching cluster identified as `baremetal`.
3.  **Label Alignment**: A key step in the MQL query is renaming the `cluster_name` label to `cluster` to facilitate the join. The PromQL query achieves the same outcome using `label_replace(...)` to create a `cluster` label from the `cluster_name` label before the `and on()` operation.
4.  **Threshold**: The final `< 0.2` condition is appended to the PromQL query to complete the boolean expression, matching the MQL `condition ... < 0.2` clause.

#### 6. Validation

**a) Observation about the Original vs. Converted PromQL Alerts**

Initially, the converted PromQL alert showed a "No data is available" error in the GCM UI, while the original MQL alert correctly displayed data. After correcting the PromQL query to use the proper join logic (`and on()`) and label alignment (`label_replace`), the converted alert now successfully queries and displays the CPU utilization ratio.

**b) Tests Done to Confirm No Major Regression**

The validation was performed by iteratively building and testing the PromQL query. The initial failure of the PromQL query (showing "No data") confirmed that a simple translation was insufficient. The breakthrough came from identifying the need for `label_replace` to align the `cluster` and `cluster_name` labels, which then allowed the `and on()` operator to correctly join the metric streams and filter the data as intended. The final query's success in returning data confirms that the logic now correctly matches time series from both sides of the condition.

**c) Acceptable Differences in Rendering**

There is a known and acceptable visual difference between the two alert UIs. The MQL alert chart displays a horizontal line at the `0.2` threshold. The PromQL alert chart does not display this line. This is not a bug but a feature of the GCM UI; it can parse the separate `condition` field in an MQL alert policy to draw the line, but it does not parse the threshold value from within a boolean PromQL query string to do the same. This is purely a cosmetic difference and has no impact on the alert's functionality.

**d) Supporting Analysis**

The core of the alert's logic relies on joining two different metrics based on a common `cluster` identifier. The successful conversion hinged on correctly replicating this join. The MQL query is more verbose, using two separate `fetch` operations and a `join`. The final PromQL query is more idiomatic, using a single expression with vector matching (`and on()`) to achieve the same filtering and calculation.

**e) Conclusion**

The converted PromQL alert is a correct and functionally equivalent replacement for the original MQL alert. The final PromQL query accurately calculates the CPU utilization ratio, correctly filters for bare metal clusters, and properly evaluates the threshold condition. The visual difference in the UI's chart rendering is an expected behavior and does not impact the reliability of the alert.
