### MQL to PromQL Conversion Validation: External Secrets Down

This report summarizes the conversion of the "External Secrets down (critical)" alert policy from MQL to PromQL.

#### 1. Original Alert Definition

*   **Name:** External Secrets down (critical)
*   **File:** `alerts/system/externalsecrets-down-30m.yaml`

#### 2. Original MQL Query

```mql
{ t_0:
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/uptime'
    | filter (resource.container_name =~ 'external-secrets')
    | align mean_aligner()
    | group_by 1m, [value_up_mean: mean(value.uptime)]
    | every 1m
    | group_by [resource.project_id, resource.location, resource.cluster_name],
        [value_up_mean_aggregate: aggregate(value_up_mean)]
  ; t_1:
    fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
    | filter (metric.anthos_distribution = 'baremetal')
    | align mean_aligner()
    | group_by [resource.project_id, resource.location, resource.cluster_name],
        [value_anthos_cluster_info_aggregate:
          aggregate(value.anthos_cluster_info)]
    | every 1m }
| join
| value [t_0.value_up_mean_aggregate]
| window 1m
| absent_for 1800s
```

#### 3. Goal of the Alert ("the Why")

The goal of this alert is to detect when the External Secrets service is down on a bare-metal cluster. It identifies clusters where the uptime metric for the `external-secrets` container has been absent for a continuous period of 30 minutes.

#### 4. Converted PromQL Query

```promql
(max by (project_id, location, cluster_name) (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"})) unless on(project_id, location, cluster_name) (avg by (project_id, location, cluster_name) (kubernetes_io:anthos_container_uptime{container_name=~"external-secrets", monitored_resource="k8s_container"}))
```

#### 5. Reasoning for Conversion ("the How")

The original MQL alert uses a `join` to filter for bare-metal clusters and an `absent_for` condition to detect the missing uptime metric. The PromQL query correctly replicates this logic using a more idiomatic approach for set operations.

1.  **Identify Bare-metal Clusters**: The `max by (...) (kubernetes_io:anthos_anthos_cluster_info{...})` part of the query generates a list of all clusters designated as "baremetal".
2.  **Identify Running `external-secrets` Instances**: The `avg by (...) (kubernetes_io:anthos_container_uptime{...})` part generates a list of all clusters where `external-secrets` is currently reporting uptime data.
3.  **Find the Difference with `unless`**: The `unless` operator performs a set difference. It takes the complete list of bare-metal clusters and removes the ones where `external-secrets` is running. The result is the exact list of bare-metal clusters where the `external-secrets` metric is absent.
4.  **Explicit Join with `on()`**: The `on(project_id, location, cluster_name)` clause ensures the matching between the two datasets is explicit and reliable, preventing failures due to inconsistent labels.
5.  **Alert Condition**: The alert policy's `duration` of 30 minutes (`1800s`) is applied to the result of this query. An alert will fire for any cluster that remains in the final list for the specified duration.

#### 6. Validation

*   **Observation about Alerts**: The initial converted PromQL query was incorrect and showed "No data is available". The original MQL alert, however, was correctly firing and creating incidents. After the final correction to the PromQL query, the converted alert also began firing incidents correctly, demonstrating functional parity.

*   **Tests Done to Confirm No Regression**: The validation was performed by observing the live behavior of both alert policies in the GCM UI. The initial failure of the PromQL alert confirmed that an incorrect query structure (using `label_replace` and implicit joins) was the root cause. The success of the final query, which uses a direct `unless on(...)` operation, confirmed that this is the correct and robust pattern for this type of absence detection.

*   **Acceptable Differences in Rendering**: There is a difference in how the charts are displayed. The MQL alert chart shows the uptime value when present, while the PromQL alert chart shows a value of `1` for clusters where the uptime is absent. This is an expected and acceptable difference, as the PromQL query is designed to show the alert condition itself, not the underlying metric.

*   **Supporting Analysis**: The troubleshooting process revealed that using `unless on(...)` is the correct PromQL idiom to replicate an MQL `absent_for` condition that is filtered by a `join`. This avoids complex and error-prone `label_replace` functions and provides a clear, readable query that is easy to maintain.

*   **Conclusion**: The converted PromQL alert policy is a correct and reliable replacement for the original MQL policy. It successfully identifies and alerts on individual bare-metal clusters where the `external-secrets` service is down, fulfilling the original intent with a more robust and idiomatic PromQL query.
