### MQL to PromQL Conversion Validation: Multiple Nodes Not Ready (Realtime)

This report summarizes the conversion of the `Multiple nodes not ready (critical)` alert policy from MQL to PromQL.

**1. Original Alert Definition:**

`alerts/node/multiple-nodes-not-ready-realtime.yaml`

**2. Original MQL Query:**

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
*(Source: `multiple-nodes-not-ready-realtime.yaml`)*
The alert policy trigger is `count: 2` and duration is `60s`.

**3. Goal of the Alert ("the Why"):**

The alert is designed to trigger if **two or more** baremetal clusters have at least one node that is not in a 'Ready' state for more than 60 seconds. It identifies widespread node health issues across the baremetal fleet.

**4. Converted PromQL Query:**

```promql
count((label_replace(count by (project_id, location, cluster) ({"__name__"="kubernetes.io/anthos/kube_node_status_condition/gauge","condition"="Ready","status"!="true"}) > 0, "cluster_name", "$1", "cluster", "(.*)")) * on(cluster_name) group_left() (max by (project_id, location, cluster_name) ({"__name__"="kubernetes.io/anthos/anthos_cluster_info", "monitored_resource"="k8s_container", "anthos_distribution"="baremetal"}))) >= 2
```
*(Source: `multiple-nodes-not-ready-realtime-promql.yaml`)*

**5. Reasoning for Conversion ("the How"):**

The MQL query joins two sets of data: nodes that are not ready and clusters that are baremetal. The PromQL query replicates this logic:

1.  **Identify Not Ready Nodes:** `{"__name__"="kubernetes.io/anthos/kube_node_status_condition/gauge","condition"="Ready","status"!="true"}` selects the node status metric for nodes not in a ready state.
2.  **Group by Cluster:** `count by (project_id, location, cluster) (...) > 0` counts how many nodes are not ready per cluster, and `> 0` results in a series for each cluster having at least one not-ready node.
3.  **Label Alignment:** Crucially, the node status metric uses a `cluster` label, while `anthos_cluster_info` uses `cluster_name`. `label_replace(..., "cluster_name", "$1", "cluster", "(.*)")` adds a `cluster_name` label to the node status results, making the join possible.
4.  **Identify Baremetal Clusters:** `max by (project_id, location, cluster_name) ({"__name__"="kubernetes.io/anthos/anthos_cluster_info", "monitored_resource"="k8s_container", "anthos_distribution"="baremetal"})` selects baremetal clusters. The `monitored_resource` label is required to resolve ambiguity.
5.  **Join:** The `* on(cluster_name) group_left()` performs the join, keeping only clusters that are both baremetal and have not-ready nodes.
6.  **Trigger Condition:** `count(...) >= 2` counts the number of resulting cluster series and evaluates to true if the count is two or more, matching the MQL trigger condition.

**6. Validation:**

*   **a) Observations:** The original MQL alert chart displays the mean of the gauge for each cluster, likely resulting in values between 0 and 1. The PromQL alert chart in the GCM UI shows the result of the `count()` function, which is the number of clusters meeting the criteria. The chart ranges from 2 to 6, indicating the number of clusters with not-ready nodes at different times.

*   **b) Tests Done:** Each component of the PromQL query was tested in Metrics Explorer during the troubleshooting phase:
    *   The node status query with the `cluster` label was confirmed to return data.
    *   The `anthos_cluster_info` query with `monitored_resource="k8s_container"` was confirmed to return data.
    *   The need for `label_replace` to align `cluster` with `cluster_name` was identified as essential for the join to succeed.
    *   The final query without the outer `count()` was observed to return the individual clusters, and with the `count()`, it returned the number of such clusters.

*   **c) Acceptable Differences:** The chart visualization differs. MQL shows the underlying metric per cluster, while PromQL shows the boolean result of the alert condition. This difference is acceptable because the PromQL chart accurately reflects the state of the *alert condition* (i.e., is it true that 2 or more clusters are firing?). The value on the graph directly shows how many clusters are currently meeting the "not ready" and "baremetal" criteria.

*   **d) Supporting Points:** The step-by-step construction and debugging confirmed that each part of the PromQL query correctly selects and filters the data as intended, mirroring the MQL logic. The use of `label_replace` was key to overcoming label inconsistencies between the metrics.

*   **e) Conclusion:** The converted PromQL alert policy is a correct and functional replacement for the original MQL policy. It accurately implements the desired logic of alerting when two or more baremetal clusters have one or more nodes in a "Not Ready" state. The difference in chart visualization is expected given the nature of the PromQL query, which evaluates the complete condition.
