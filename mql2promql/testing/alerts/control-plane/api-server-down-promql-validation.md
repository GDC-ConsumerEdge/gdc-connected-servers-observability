### alerts/control-plane/apiserver-down.yaml

The conversion of the MQL-based alert policy for a down API server to PromQL is correct. The final PromQL query is functionally equivalent to the original MQL, successfully translating the core logic for filtering, absence detection, and resource scoping.

| Feature | Original MQL Alert | Converted PromQL Alert | Rationale |
| :--- | :--- | :--- | :--- |
| **Goal** | Alert when the `kube-apiserver` uptime metric has been missing for 5 minutes, specifically on "baremetal" clusters. | Same. | The fundamental goal is identical. |
| **Filtering for Bare Metal** | Uses a `join` operation to filter for time series where `metric.anthos_distribution = 'baremetal'`. | Uses the `unless` operator with `kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal"}`. | **Match.** The PromQL `unless` operator provides the same filtering capability as the MQL `join` for this use case. |
| **Detecting Absence** | Uses the `absent_for 300s` condition to check if the uptime metric is missing for 5 minutes. | The `unless` operator returns a result when the uptime metric is missing. The policy's `duration: 300s` ensures this condition must persist for 5 minutes. | **Match.** The combination of the `unless` operator and the alert policy's `duration` is functionally equivalent to MQL's `absent_for`. |
| **Specifying Resource Type** | Explicitly fetches the `k8s_container` resource. | Adds the `monitored_resource="k8s_container"` label to both metrics in the query. | **Match.** Both alerts are correctly scoped to the `k8s_container` resource, which was a necessary fix to resolve ambiguity errors in PromQL. |

#### Final PromQL Query

```promql
kubernetes_io:anthos_anthos_cluster_info{monitored_resource="k8s_container", anthos_distribution="baremetal"} unless on(cluster_name, location, project_id) kubernetes_io:anthos_container_uptime{monitored_resource="k8s_container", container_name=~"kube-apiserver"}
```

#### Explanation of UI Differences

A key point of confusion during the conversion was the visualization in the Google Cloud Monitoring UI.

*   **MQL Alert View:** The chart displays the value of the `container/uptime` metric itself. As long as the API servers are up, the chart shows data points.
*   **PromQL Alert View:** The chart displays the output of the `unless` query. This query is designed to **only return a result when there is a problem** (i.e., when an API server is down).

Therefore, the "No data is available..." message in the PromQL alert view is the correct and expected behavior for a healthy system. It confirms that the alert condition is not currently met.

#### Conclusion

The final PromQL alert policy is a correct and reliable replacement for the original MQL policy. All functional aspects have been accurately translated. The observed difference in the UI chart is not a bug, but a correct representation of the different query strategies, where the PromQL alert only shows data when a problem is detected.

