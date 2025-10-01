Of course. Here is a summary of the changes for the Code Agent to update the PromQL policy YAML file based on our analysis.

### Summary of Changes for `externalsecrets-down-30m-promql.yaml`

**File to be Updated:**
`mql2promql/alerts-promql/system/externalsecrets-down-30m-promql.yaml`

**Action:**
The `query` field within the `conditionPrometheusQueryLanguage` block needs to be replaced.

**Current (Incorrect) Query:**
The existing query in the file is:
```yaml
query: '(max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) unless (avg by (cluster, location, project_id) (kubernetes_io:anthos_container_uptime{container_name=~"external-secrets", monitored_resource="k8s_container"}))'
```

**New (Corrected) Query:**
The agent should replace the old query with the following corrected version:
```yaml
query: '(max by (project_id, location, cluster_name) (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"})) unless on(project_id, location, cluster_name) (avg by (project_id, location, cluster_name) (kubernetes_io:anthos_container_uptime{container_name=~"external-secrets", monitored_resource="k8s_container"}))'
```

**Reasoning for the Change:**
The updated query corrects the following issues found in the original PromQL conversion:
1.  **Removes Unnecessary `label_replace`**: The `label_replace` function was redundant.
2.  **Corrects Label Grouping**: It now groups by `cluster_name` on both sides of the `unless` operator, which is the correct label present in both metrics.
3.  **Adds Explicit Matching with `on()`**: It introduces an `on(project_id, location, cluster_name)` clause to ensure the `unless` operator reliably matches time series between the two sides of the query based on a shared context.

This change will make the PromQL alert robust and functionally identical to the original MQL alert, as we have already validated through the GCM UI.
