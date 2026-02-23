# MQL to PromQL Conversion Guide - Node Not Ready 30m

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/node/node-not-ready-30m.yaml` alert.

## `alerts/node/node-not-ready-30m.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Node not ready for more than 30 minutes | MQL | `fetch prometheus_target \| metric 'kubernetes.io/anthos/kube_node_status_condition/gauge' \| ...` | The PromQL query was constructed to meet the user's desired per-node alerting behavior. It uses `count by (node, ...)` to create a distinct time series for each node that is not ready, which differs from the MQL's per-cluster grouping. | PromQL | `(count by (node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_condition_gauge{condition!="Ready", status="true"})) and on(cluster, location, project_id) (max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) > 0` | The primary difference is the alert granularity (per-node vs. per-cluster). This is a desired improvement that aligns the alert's behavior with the user's goal. |

---

### MQL to PromQL Conversion Validation: Node Not Ready

This report summarizes the conversion of the **Node not ready for more than 30 minutes (critical)** alert policy from MQL to PromQL.

#### 1. Original Alert Definition

*   **Name:** `Node not ready for more than 30 minutes (critical)`
*   **File:** `alerts/node/node-not-ready-30m.yaml`

#### 2. Original MQL Query
```mql
{ t_0:
  fetch prometheus_target
  | metric 'kubernetes.io/anthos/kube_node_status_condition/gauge'
  | filter (metric.condition != 'Ready' && metric.status == 'true')
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
The alert policy has a `duration` of `1800s`.

#### 3. Goal of the Alert ("the Why")

The original MQL alert's goal was to detect if **any** node within a baremetal cluster was in a "Not Ready" state for more than 30 minutes. Due to its `group_by` clause, which aggregates at the cluster level, it was designed to fire a single alert per affected cluster. The user clarified that the desired behavior is actually to fire a distinct alert for **each** individual node that is not ready, making the alerting more granular and actionable.

#### 4. Converted PromQL Query
```promql
(count by (node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_condition_gauge{condition!="Ready", status="true"})) and on(cluster, location, project_id) (max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) > 0
```
This query is used in an alert policy with a `duration` of `1800s`.

#### 5. Reasoning for Conversion ("the How")

The PromQL query was constructed to meet the user's desired per-node alerting behavior while retaining the core logic of the MQL alert.

1.  **Identify Not Ready Nodes:** The `kubernetes_io:anthos_kube_node_status_condition_gauge{condition!="Ready", status="true"}` part selects the raw metric for nodes that are not ready, which is equivalent to the MQL `filter`.
2.  **Per-Node Grouping:** The `count by (node, cluster, location, project_id)` is the most critical part. It creates a distinct time series for **each node** that is not ready. This directly implements the user's requirement for per-node alerting, differing from the MQL's per-cluster grouping.
3.  **Filter for Baremetal Clusters:** The `and on(cluster, location, project_id) (...)` logic performs a vector match that acts as a filter. It ensures that only time series for nodes belonging to a baremetal cluster are kept. This is the PromQL equivalent of the MQL `join`.
4.  **Align Cluster Labels:** The `label_replace(...)` function solves a label mismatch between the two metrics by creating a common `cluster` label, which is necessary for the `and on()` to work correctly.

#### 6. Validation

*   **a) Observation about Alerts:** The original MQL alert was configured to fire once per cluster. The converted PromQL alert correctly fires once per node. This is a deliberate and desired change in granularity that better reflects the user's intent. The GCM UI for the PromQL alert confirms this, showing multiple open incidents for individual nodes.

*   **b) Tests Done to Confirm No Regression:** The converted PromQL query was tested in the Metrics Explorer. The chart correctly displayed time series data for each individual node that was not in a "Ready" state, validating that the per-node grouping and filtering logic is functioning as intended.

*   **c) Acceptable Differences:** The primary difference is the alert granularity (per-node vs. per-cluster). This is not a regression but a desired improvement that aligns the alert's behavior with the user's stated goal of being notified for each specific node that is down. The charts in the UI will also differ; the MQL chart shows a cluster-level aggregation, while the PromQL chart shows individual series for each node. This is an expected and acceptable consequence of the improved granularity.

*   **d) Supporting Analysis:** The PromQL query is a more direct and precise implementation of the desired alerting logic. By grouping by `node`, it provides more actionable alerts, immediately identifying the specific infrastructure component that requires attention.

*   **e) Conclusion:** The converted PromQL alert is a correct and superior implementation for the stated goal. It successfully identifies and alerts on individual "Not Ready" nodes within baremetal clusters, providing more granular and actionable notifications than the original MQL alert.
