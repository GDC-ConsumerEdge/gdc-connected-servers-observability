Here is a summary of the required code change for the Coding Agent to update the YAML file.

### Summary for Coding Agent

**Objective:** Update the converted PromQL alert to correctly replicate the logic of the original MQL alert, which is designed to fire only when the heartbeat signal has been completely absent for a sustained period of 5 minutes.

**File to Modify:**
`mql2promql/alerts-promql/vm-workload/vmruntime-heartbeats-realtime-promql.yaml`

**Change Description:**
The current PromQL query is incorrect because it triggers an alert instantaneously if the metric's value is not `1`, failing to check for a sustained 5-minute absence as the original MQL alert did. The query must be replaced with one that counts the metric's data points over a 5-minute window and triggers only if that count is zero.

Additionally, the `displayName` of the policy and the condition should be updated to more accurately reflect this logic.

---

### Implementation Details:

Please replace the `conditions` block in the specified file.

**Current `conditions` block to be replaced:**
```yaml
conditions:
- conditionPrometheusQueryLanguage:
    query: "avg by(cluster_name) (kubernetes_io:anthos_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics{monitored_resource=\"k8s_container\"}) != 1"
    displayName: VMRuntime Heartbeat is up - PromQL
```

**New `conditions` block to implement:**
```yaml
conditions:
- conditionPrometheusQueryLanguage:
    query: "count_over_time(kubernetes_io:anthos_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics{monitored_resource=\"k8s_container\"}[5m]) == 0"
    duration: "0s"
    trigger:
      count: 1
    displayName: VMRuntime Heartbeat Absent for 5m - PromQL
```

**Also, update the root `displayName` for the policy:**

**Current `displayName`:**
```yaml
displayName: VMRuntime Heartbeat down (critical) - converted to PromQL
```

**New `displayName`:**
```yaml
displayName: VMRuntime Missing Heartbeat (critical) - converted to PromQL
```
