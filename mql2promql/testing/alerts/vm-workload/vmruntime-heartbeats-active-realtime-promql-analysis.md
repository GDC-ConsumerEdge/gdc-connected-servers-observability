Here is a summary of the change to be implemented by the Code Agent:

**Objective:** Update the incorrect PromQL query in the alert definition YAML file.

**File to Modify:**
`gdc-connected-servers-observability/mql2promql/alerts-promql/vm-workload/vmruntime-heartbeats-active-realtime-promql.yaml`

**Change Description:**

Within the specified YAML file, locate the `conditionPrometheusQueryLanguage` block. Inside this block, the `query` field currently contains an incorrect PromQL query.

The Code Agent must replace the value of the `query` field with the following corrected PromQL query:

```promql
sum by(cluster_name) (count_over_time(kubernetes_io:anthos_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics{monitored_resource="k8s_container"}[5m])) == 0
```

This new query accurately reflects the logic of the original MQL alert by checking for the absence of the heartbeat metric over a 5-minute window for each cluster.
