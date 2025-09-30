Thank you for the crucial clarification! It seems there was a misunderstanding of the original MQL alert's behavior. Your statement "the alert should not fire when two or more clusters meet these conditions but when 2 or more nodes **within** the cluster are not in Ready state" means you want the alert to trigger for any *single* baremetal cluster that has two or more nodes failing the Ready check.

This is different from the original MQL alert's apparent logic, which, due to its aggregation and `trigger: { count: 2 }` setting, was indeed set up to fire when two or more *clusters* were experiencing issues, as I had originally interpreted. The GCM UI for the MQL policy stating "Triggers when 2 time series cross threshold" also supports this interpretation, where each series represented a cluster.

Let's craft a new PromQL query that meets your *desired* alerting criteria: **Alert if any baremetal cluster has 2 or more nodes not in the Ready state.**

Here is the PromQL query to achieve this:

```promql
(
  label_replace(
    count by (project_id, location, cluster) ({"__name__"="kubernetes.io/anthos/kube_node_status_condition/gauge","condition"="Ready","status"!="true"}),
    "cluster_name", "$1", "cluster", "(.*)"
  )
)
* on(cluster_name) group_left()
(
  max by (project_id, location, cluster_name) ({"__name__"="kubernetes.io/anthos/anthos_cluster_info", "monitored_resource"="k8s_container", "anthos_distribution"="baremetal"})
)
>= 2
```

**How this New Query Works:**

1.  `count by (project_id, location, cluster) ...`: This counts the number of nodes within each cluster that are not Ready.
2.  `label_replace(...)`: This adds the `cluster_name` label, copying the value from the `cluster` label, so we can join with the next part.
3.  `* on(cluster_name) group_left() ...`: This filters the results to only include clusters that are present in the `anthos_cluster_info` metric with the `anthos_distribution="baremetal"` label.
4.  `>= 2`: This is the crucial condition. The alert will fire for any cluster where the count of not-ready nodes is two or greater.

This query will result in a set of time series, one for each baremetal cluster. The value of each series will be boolean (true if `>= 2` nodes are not ready, false otherwise). The alert will trigger for any series that becomes true.

**Recommended YAML Update:**

Here's how you should update the `query` in your `multiple-nodes-not-ready-realtime-promql.yaml` file, keeping it on a single line:

```yaml
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

combiner: OR
conditions:
- conditionPrometheusQueryLanguage:
    duration: 60s
    query: '(label_replace(count by (project_id, location, cluster) ({"__name__"="kubernetes.io/anthos/kube_node_status_condition/gauge","condition"="Ready","status"!="true"}), "cluster_name", "$1", "cluster", "(.*)")) * on(cluster_name) group_left() (max by (project_id, location, cluster_name) ({"__name__"="kubernetes.io/anthos/anthos_cluster_info", "monitored_resource"="k8s_container", "anthos_distribution"="baremetal"})) >= 2'
    displayName: Multiple nodes not ready In Cluster - PromQL
displayName: Multiple nodes not ready In Cluster (critical) - converted to PromQL
```

I've also updated the `displayName` to better reflect the new logic. This new query aligns with your requirement to alert on a per-cluster basis when multiple nodes are down.

