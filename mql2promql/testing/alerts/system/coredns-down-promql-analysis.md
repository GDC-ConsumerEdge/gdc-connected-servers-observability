Here is a summary of the required change for the MQL2PromQL Dev Agent.

---

### Summary of Change for `coredns-down-promql.yaml`

**1. File to be Updated:**

Please update the following file:
`mql2promql/alerts-promql/system/coredns-down-promql.yaml`

**2. The Change:**

The `query` field within the `conditionPrometheusQueryLanguage` block needs to be replaced.

**Replace the old query:**
```yaml
query: 'absent((sum by (cluster, location, project_id) (kubernetes_io:anthos_container_uptime{container_name=~"coredns"})) and on(cluster, location, project_id) (max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))))'
```

**With the new, corrected query:**
```yaml
query: '(max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}, "cluster", "$1", "cluster_name", "(.*)"))) unless (avg by (cluster, location, project_id) (kubernetes_io:anthos_container_uptime{container_name=~"coredns", monitored_resource="k8s_container"}))'
```

**3. Reason for the Change:**

The initial PromQL conversion used an `absent()` function combined with an `and` operator. This approach incorrectly collapsed all the individual cluster metrics into a single boolean result, preventing the alert from firing on a per-cluster basis. The original MQL alert correctly triggered incidents for each specific cluster that was down.

The new query uses the `unless` operator to perform a set difference. It correctly identifies which clusters are expected to be running but are not reporting a `coredns` uptime metric. This restores the intended per-cluster alerting behavior, as confirmed by the GCM UI now showing distinct time series for each affected cluster. The use of `avg` also aligns better with the original MQL query's `mean` aggregation.
