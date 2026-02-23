Of course. Here is a summary for the developer on how to update the PromQL YAML file for the "Node memory usage exceeds 80 percent (critical)" alert.

---

### Summary for Updating `node-memory-usage-high-promql.yaml`

To fix the **Node memory usage exceeds 80 percent (critical) - converted to PromQL** alert, the PromQL query needs to be updated. The previous versions of the query either failed to return data or did not allow for proper filtering and visualization by cluster in the Google Cloud Monitoring UI.

The solution was to adopt the successful query structure from the "Node CPU Usage High" alert. This structure correctly handles filtering for baremetal clusters and ensures the necessary labels are available for the UI to use.

**File to Edit:** `mql2promql/alerts-promql/node/node-memory-usage-high-promql.yaml`

**Required Change:**

Replace the existing `query` in the `conditionPrometheusQueryLanguage` block with the following corrected query. It must be on a single line.

```yaml
query: '(sum by(node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_allocatable_gauge{resource="memory"}) / sum by(node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_capacity_gauge{resource="memory"})) and on(cluster, location, project_id) (max by(cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) < 0.2'
```

### Explanation of the Fix:

*   **Problem**: The previous query for memory usage did not correctly join metrics to allow for filtering by cluster, which was a key requirement.
*   **Solution**: The new query mirrors the logic from the working "Node CPU Usage High" alert.
    1.  **Calculates Ratio**: It calculates the ratio of `allocatable` memory to `capacity` memory for each node, using the `...kube_node_status..._gauge` metrics with the label `resource="memory"`.
    2.  **Filters for Baremetal**: It uses the `and on(...)` operator to join the memory ratio with the `kubernetes_io:anthos_anthos_cluster_info` metric. This acts as a filter, ensuring the alert only considers nodes on clusters with `anthos_distribution="baremetal"`.
    3.  **Aligns Labels**: It uses `label_replace(...)` to create a common `cluster` label, which solves the label mismatch between the node metrics and the cluster info metric, allowing the join to succeed.
    4.  **Applies Threshold**: The `< 0.2` condition correctly triggers the alert when allocatable memory is less than 20% of capacity.

This updated query is confirmed to return the correct data and allows for the expected filtering and visualization behavior in the Google Cloud Monitoring UI.
