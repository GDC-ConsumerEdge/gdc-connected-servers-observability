Of course. Here is a summary for the developer on how to update the PromQL YAML file.

***

### Summary for Updating `node-cpu-usage-high-promql.yaml`

To fix the `Node cpu usage exceeds 80 percent (critical) - converted to PromQL` alert, you need to update the PromQL query in the corresponding YAML file.

**File to Edit:** `mql2promql/alerts-promql/node/node-cpu-usage-high-promql.yaml`

**Problem:** The current query incorrectly uses a multiplication operator (`*`) to filter for bare metal clusters, which results in no data being returned. The original MQL alert uses a `join` to filter, and the correct PromQL equivalent is the `and` operator.

**Required Change:**

Replace the existing `query` in the `conditionPrometheusQueryLanguage` block with the following corrected query. This query must be on a single line.

```yaml
query: (sum by(node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_allocatable_gauge{resource="cpu"}) / sum by(node, cluster, location, project_id) (kubernetes_io:anthos_kube_node_status_capacity_gauge{resource="cpu"})) and on(cluster, location, project_id) (max by(cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) < 0.2
```

This corrected query properly uses the `and on()` operator to match the CPU ratio with the bare metal cluster information, ensuring the alert logic is equivalent to the original MQL query and functions correctly.
