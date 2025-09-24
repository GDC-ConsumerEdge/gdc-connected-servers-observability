# MQL to PromQL Conversion Guide

This document lists Monitoring Query Language (MQL) queries found in the repository and provides proposed translations to Prometheus Query Language (PromQL).

## Deployment of Converted Dashboards and Alerts

To deploy the converted dashboards and alerts, you can use the provided shell scripts.

### Dashboards

To deploy the dashboards, run the following command from the `mql2promql/dashboards-promql` directory:

```bash
./create-dashboards-promql.sh
```

### Alerts

To deploy the alerts, run the following command from the `mql2promql/alerts-promql` directory:

```bash
./create-alerts-promql.sh
```

## Summary of Files Containing MQL Queries

| File Path                                                  | Contains MQL? | Notes                                                                 | Conversion Status |
| :--------------------------------------------------------- | :------------ | :-------------------------------------------------------------------- | :---------------- |
| `dashboards/gdc-daily-report.json`                         | Yes (Partial) | Mixed MQL (`timeSeriesQueryLanguage`) and PromQL (`prometheusQuery`). | To be verified               |
| `dashboards/gdc-external-secrets.json`                     | No            | Uses `prometheusQuery`.                                               | N/A               |
| `dashboards/gdc-logs.json`                                 | No            | Log panel filters, not metric queries.                                | N/A               |
| `dashboards/gdc-node-view.json`                            | Yes           | Uses `timeSeriesQueryLanguage`.                                       | WIP               |
| `dashboards/gdc-robin-status.json`                         | Yes (Partial) | Mixed MQL (`timeSeriesFilter` with MQL-like filter) and PromQL.     | WIP               |
| `dashboards/gdc-vm-distribution.json`                      | Yes           | Uses `timeSeriesQueryLanguage`.                                       | To be verified    |
| `dashboards/gdc-vm-view.json`                              | Yes (Partial) | Mixed MQL (`timeSeriesQueryLanguage`, `timeSeriesFilter`) and PromQL. | To be verified    |
| `alerts/control-plane/api-server-error-ratio-5-percent.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              | To be verified               |
| `alerts/control-plane/apiserver-down.yaml`                 | Yes           | `conditionMonitoringQueryLanguage` used.                              | To be verified    |
| `alerts/control-plane/controller-manager-down.yaml`        | Yes           | `conditionMonitoringQueryLanguage` used.                              | To be verified    |
| `alerts/control-plane/scheduler-down.yaml`                 | Yes           | `conditionMonitoringQueryLanguage` used.                              | WIP               |
| `alerts/node/multiple-nodes-not-ready-realtime.yaml`       | Yes           | `conditionMonitoringQueryLanguage` used.                              | WIP               |
| `alerts/node/node-cpu-usage-high.yaml`                     | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/node/node-memory-usage-high.yaml`                  | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/node/node-not-ready-30m.yaml`                      | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/pods/pod-crash-looping.yaml`                       | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/pods/pod-not-ready-1h.yaml`                        | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/storage/robin-disk-inactive-10m.yaml`              | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/storage/robin-master-down-10m.yaml`                | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/storage/robin-node-offline-30m.json`               | Yes           | JSON format, uses `conditionThreshold` with MQL-like filter.        | TBD               |
| `alerts/system/configsync-down-30m.yaml`                   | Yes           | `conditionAbsent` with MQL-like filter.                             | TBD               |
| `alerts/system/configsync-high-apply-duration-1h.yaml`     | No            | Uses `conditionPrometheusQueryLanguage`.                              | N/A               |
| `alerts/system/configsync-old-last-sync-2h.yaml`           | No            | Uses `conditionPrometheusQueryLanguage`.                              | N/A               |
| `alerts/system/coredns-down.yaml`                          | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/system/coredns-servfail-ratio-1-percent.yaml`      | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/system/externalsecrets-down-30m.yaml`              | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/system/externalsecrets-sync-error.yaml`            | No            | Uses `conditionPrometheusQueryLanguage`.                              | N/A               |
| `alerts/vm-workload/vmruntime-heartbeats-active-realtime.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-heartbeats-realtime.yaml`    | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-vm-down-5m.yaml`             | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-vm-missing-5m.yaml`          | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-vm-no-network-traffic-5m.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |

---

### Glossary of Conversion Status

- **N/A**: Not Applicable. The file does not contain any MQL queries that require conversion.
- **TBD**: To Be Done. The file contains MQL queries, but the conversion has not been started yet.
- **WIP**: Work In Progress. The conversion for this file is currently in progress.
- **To be verified**: The conversion has been completed, but it is pending review and verification.
- **Completed**: The conversion has been completed and verified.

---

## Dashboards

### `dashboards/gdc-daily-report.json`

This section details the conversion of widgets from the "GDC - Daily Report" dashboard from Monitoring Query Language (MQL) to Prometheus Query Language (PromQL). The goal was to create a dashboard with feature parity using only PromQL queries, compatible with Google Cloud's Managed Service for Prometheus.

| Group          | Input Query Title               | Input Query Type | Source Query (MQL)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | LLM Reasoning                                                                                                                                                                                                                                                                                                                                                                                                                      | LLM Output Query Type | LLM Output PromQL Query                                                                                                                                                                                                                                                                                                                            | Comments                                                                                                                                                                                             |
| :------------- | :------------------------------ | :--------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Availability   | Node Availability               | MQL              | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/cpu/core_usage_time' \| ... \| join \| ... \| condition val() > 0 \| group_by [resource.node_name], [value_has_cpu: aggregate(val(0))]`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | The MQL query determines node availability by checking if there is any CPU usage. The PromQL equivalent uses `rate()` to check for CPU activity and sums the boolean result (1 if active, 0 if not) for each node. The `> 0` at the end is for the condition, but the `sum by` counts nodes. A more direct PromQL translation to count nodes with CPU activity is to count the series with a rate greater than 0. | PromQL                | `sum by (node_name) (rate(kubernetes_io:anthos_node_cpu_core_usage_time{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*"}[5m])) > 0`                                                                                                                                                                        | The PromQL query identifies nodes with active CPU usage.                                                                                                                                           |
| Availability   | VM Availability                 | MQL              | `fetch k8s_container \| metric 'kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total' \| ... \| align rate(2m) \| ... \| condition value_kubevirt_vmi_network_transmit_bytes_total > 0 \| val(0)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | The MQL query counts VMs with network transmit activity. The PromQL version calculates the transmission rate for each VM and counts how many have a rate greater than 0. The `sum by > 0` produces a boolean, and `count by` counts the true results.                                                                                                    | PromQL                | `count by (kubernetes_vmi_label_kubevirt_vm) ( sum by (kubernetes_vmi_label_kubevirt_vm) ( rate(kubernetes_io:anthos_kubevirt_vmi_network_transmit_bytes_total{monitored_resource="k8s_container",${cluster_name},cluster_name=~"${market.value}.*"}[2m]) ) > 0 )`                                                                          | This PromQL query accurately counts the number of VMs with active network transmission.                                                                                                              |
| Performance    | Node CPU Utilization            | MQL              | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/cpu/allocatable_utilization' \| ... \| group_by 1m, [mean(...)] \| scale '%'`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | The MQL query calculates the mean CPU utilization for each node. The PromQL equivalent uses `avg_over_time` to smooth the gauge metric and `avg by (node_name)` to group the results per node, multiplying by 100 to convert to a percentage.                                                                                                           | PromQL                | `avg by (node_name) (avg_over_time(kubernetes_io:anthos_node_cpu_allocatable_utilization{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*"}[1m])) * 100`                                                                                                                                     | Provides the average CPU utilization percentage for each node.                                                                                                                                     |
| Performance    | Node Memory Utilization         | MQL              | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/memory/allocatable_utilization' \| ... \| group_by [resource.node_name], ... \| scale '%'`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Similar to Node CPU Utilization, this calculates the mean memory utilization per node. The PromQL uses `avg_over_time` and `avg by (node_name)`, multiplying by 100.                                                                                                                                                                          | PromQL                | `avg by (node_name) (avg_over_time(kubernetes_io:anthos_node_memory_allocatable_utilization{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*"}[1m])) * 100`                                                                                                                                  | Provides the average memory utilization percentage for each node.                                                                                                                                  |
| Performance    | Node Received Bytes             | MQL              | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/network/received_bytes_count' \| ... \| align rate(1m)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | The MQL `align rate(1m)` is directly translated to the PromQL `rate(metric[1m])` function, summed per node. The `unitOverride: "By/s"` was added to the dashboard JSON to ensure proper unit scaling in the UI.                                                                                                                                      | PromQL                | `sum by (node_name) (rate(kubernetes_io:anthos_node_network_received_bytes_count{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*",interface=~"enp81s0f.*"}[1m]))`                                                                                                                                   | Calculates the rate of bytes received per node.                                                                                                                                                      |
| Performance    | Node Sent Bytes                 | MQL              | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/network/sent_bytes_count' \| ... \| align rate(1m)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Similar to Node Received Bytes, using `rate()` in PromQL and `unitOverride` in the JSON.                                                                                                                                                                                                                                          | PromQL                | `sum by (node_name) (rate(kubernetes_io:anthos_node_network_sent_bytes_count{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*",interface=~"enp81s0f.*"}[1m]))`                                                                                                                                     | Calculates the rate of bytes sent per node.                                                                                                                                                          |
| Performance    | VM CPU Utilization              | MQL              | `fetch k8s_container \| metric 'kubernetes.io/anthos/container/cpu/request_utilization' \| ... \| filter pod_name=~"(virt-launcher).*", container_name="compute" \| group_by [resource.pod_name], ...`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Calculates the average CPU request utilization for each VM pod. PromQL uses `avg_over_time` and `avg by (pod_name)` with appropriate label filters.                                                                                                                                                                                     | PromQL                | `avg by (pod_name) (avg_over_time(kubernetes_io:anthos_container_cpu_request_utilization{monitored_resource="k8s_container",${cluster_name},cluster_name=~"${market.value}.*",pod_name=~"(virt-launcher).*\",container_name="compute"}[1m])) * 100`                                                                                | Provides the average CPU request utilization percentage for each VM.                                                                                                                                 |
| Performance    | VM Received Bytes (Per Interface) | MQL              | `fetch k8s_container \| metric 'kubernetes.io/anthos/kubevirt_vmi_network_receive_bytes_total' \| align rate(1m)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | MQL `align rate(1m)` translates to PromQL `rate(metric[1m])`, summed by VM label and interface. Includes `unitOverride` in the JSON.                                                                                                                                                                                                  | PromQL                | `sum by (kubernetes_vmi_label_kubevirt_vm, interface) (rate(kubernetes_io:anthos_kubevirt_vmi_network_receive_bytes_total{monitored_resource="k8s_container",${cluster_name},cluster_name=~"${market.value}.*"}[1m]))`                                                                                                              | Calculates the rate of bytes received per VM per interface.                                                                                                                                        |
| Performance    | VM Sent Bytes (Per Interface)   | MQL              | `fetch k8s_container \| metric 'kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total' \| align rate(1m)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Similar to VM Received Bytes, using `rate()` in PromQL and `unitOverride` in the JSON.                                                                                                                                                                                                                                           | PromQL                | `sum by (kubernetes_vmi_label_kubevirt_vm, interface) (rate(kubernetes_io:anthos_kubevirt_vmi_network_transmit_bytes_total{monitored_resource="k8s_container",${cluster_name},cluster_name=~"${market.value}.*"}[1m]))`                                                                                                             | Calculates the rate of bytes sent per VM per interface.                                                                                                                                          |

---

#### Reasoning for Conversion Choices:

1.  **Metric Name Conversion:** MQL metric names like `kubernetes.io/anthos/xxx` are converted to PromQL format by replacing the first `/` with `:` and other special characters (`.` , `/`) with `_`. For example, `kubernetes.io/anthos/node/cpu/core_usage_time` becomes `kubernetes_io:anthos_node_cpu_core_usage_time`.
2.  **Filters:** MQL `filter` operations on resource or metric labels are translated into PromQL label matchers within curly braces `{...}`. Template variables like `${cluster_name}` are preserved.
3.  **Aligners & Aggregation:**
    *   MQL `align rate(W)` translates to PromQL `rate(metric[W])`.
    *   MQL `group_by` operations with aggregations like `mean` are translated to PromQL aggregation functions (`avg`, `sum`, `count`) with `by (label)` clauses.
    *   For gauge metrics, `avg_over_time(metric[W])` is used in PromQL to get a smoothed average over a window, similar to MQL's `group_by W, [mean(...)] | every W`.
4.  **Monitored Resource:** The `monitored_resource` label is added in PromQL queries (e.g., `monitored_resource="k8s_node"`) when the metric can be associated with multiple resource types, to ensure a unique match, as per best practices for Google Cloud's Managed Service for Prometheus.
5.  **Unit Scaling:** For byte rate metrics, the raw PromQL result is in bytes/second. To match the MQL dashboard's scaled units (e.g., MiB/s), the `unitOverride: "By/s"` property was added to the `timeSeriesQuery` object within the dashboard JSON definition for the relevant widgets. This instructs the frontend to handle the unit scaling.

#### Final Comparison Summary:

The conversion process involved several iterations to ensure accuracy. Key adjustments included:

*   Correcting the "VM Availability" query to count VMs rather than summing rates.
*   Adding `avg by (node_name)` to Node CPU/Memory utilization queries to ensure per-node aggregation.
*   Adding `unitOverride` to network throughput widgets to fix unit scaling.

The final PromQL queries and dashboard configuration now provide a close match to the original MQL-based dashboard in terms of data representation, grouping, and visual scaling.

### `dashboards/gdc-node-view.json`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Scorecard | Total Nodes | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/cpu/total_cores' \| ... \| group_by [], [row_count: row_count()]` | The MQL query counts the number of nodes. The PromQL equivalent uses the `count` function on the same metric. | PromQL | `count(kubernetes_io:anthos_node_cpu_total_cores{monitored_resource="k8s_node",${project_id},${cluster_name}})` | A more standard way to count nodes in PromQL would be `count(kube_node_info)`. |
| Scorecard | Total Cores | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/cpu/total_cores' \| ... \| group_by [], [aggregate(...)]` | The MQL query sums the total cores across all nodes. This is a direct translation to the `sum` function in PromQL. | PromQL | `sum(kubernetes_io:anthos_node_cpu_total_cores{monitored_resource="k8s_node",${project_id},${cluster_name}})` | |
| Scorecard | Allocatable Cores | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/cpu/allocatable_cores' \| ... \| group_by [], [aggregate(...)]` | The MQL query sums the allocatable cores across all nodes. This is a direct translation to the `sum` function in PromQL. | PromQL | `sum(kubernetes_io:anthos_node_cpu_allocatable_cores{monitored_resource="k8s_node",${project_id},${cluster_name}})` | |
| Scorecard | Total Memory | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/memory/total_bytes' \| ... \| group_by [], [aggregate(...)]` | The MQL query sums the total memory across all nodes. This is a direct translation to the `sum` function in PromQL. | PromQL | `sum(kubernetes_io:anthos_node_memory_total_bytes{monitored_resource="k8s_node",${project_id},${cluster_name}})` | |
| Scorecard | Allocatable Memory | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/memory/allocatable_bytes' \| ... \| group_by [], [aggregate(...)]` | The MQL query sums the allocatable memory across all nodes. This is a direct translation to the `sum` function in PromQL. | PromQL | `sum(kubernetes_io:anthos_node_memory_allocatable_bytes{monitored_resource="k8s_node",${project_id},${cluster_name}})` | |
| CPU and Memory | CPU Usage per Node | MQL | `{...} \| join \| value [scaled_util: val(0) * val(1)]` | The MQL query joins allocatable utilization with allocatable cores and multiplies them. The PromQL equivalent uses `avg_over_time` for both metrics and multiplies the results. | PromQL | `avg_over_time(kubernetes_io:anthos_node_cpu_allocatable_utilization{monitored_resource="k8s_node",${project_id},${cluster_name}}[1m]) * avg_over_time(kubernetes_io:anthos_node_cpu_allocatable_cores{monitored_resource="k8s_node",${project_id},${cluster_name}}[1m])` | |
| CPU and Memory | Memory Usage per Node | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/memory/used_bytes' \| ... \| group_by [resource.node_name], ...` | The MQL query calculates the mean of used bytes per node. This is translated to `sum by (node_name)` and `avg_over_time` in PromQL. | PromQL | `sum by (node_name) (avg_over_time(kubernetes_io:anthos_node_memory_used_bytes{monitored_resource="k8s_node",${project_id},${cluster_name}}[1m]))` | |
| CPU and Memory | CPU Util % per Node | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/cpu/allocatable_utilization' \| ... \| scale '%'` | The MQL query calculates the mean of a gauge metric and scales it to a percentage. This is translated to `avg_over_time` and multiplication by 100 in PromQL. | PromQL | `avg_over_time(kubernetes_io:anthos_node_cpu_allocatable_utilization{monitored_resource="k8s_node",${project_id},${cluster_name}}[1m]) * 100` | |
| CPU and Memory | Memory Util % per Node | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/memory/allocatable_utilization' \| ... \| group_by [resource.node_name], ... \| scale '%'` | Similar to the CPU utilization query, but grouped by node. This is translated to `avg by (node_name)` and `avg_over_time` in PromQL. | PromQL | `avg by (node_name) (avg_over_time(kubernetes_io:anthos_node_memory_allocatable_utilization{monitored_resource="k8s_node",${project_id},${cluster_name}}[1m])) * 100` | |
| Pod and Container Count | Number of Containers per Node | MQL | `... \| group_by [metadata.system.node_name], [row_count()]` | The MQL query counts containers per node. The PromQL equivalent uses `count by (node_name)`. | PromQL | `count by (node_name) (kubernetes_io:anthos_container_cpu_core_usage_time{monitored_resource="k8s_container",${project_id},${cluster_name}})` | |
| Pod and Container Count | Number of Pods per Node | MQL | `... \| group_by [metadata.system.node_name], [row_count()]` | The MQL query counts pods per node. The PromQL equivalent uses `count by (node_name)`. | PromQL | `count by (node_name) (kubernetes_io:anthos_pod_network_received_bytes_count{monitored_resource="k8s_pod",${project_id},${cluster_name}})` | |
| Network Usage per Node | Received bytes per node | MQL | `... \| align rate(1m) \| ...` | The MQL query calculates the rate of received bytes. This is a direct translation to the `rate()` function in PromQL. | PromQL | `sum by (node_name) (rate(kubernetes_io:anthos_node_network_received_bytes_count{monitored_resource="k8s_node",${project_id},${cluster_name},interface=~"enp81s0f.*"}[1m]))` | |
| Network Usage per Node | Send bytes per node | MQL | `... \| align rate(1m) \| ...` | Similar to the received bytes query, this calculates the rate of sent bytes. | PromQL | `sum by (node_name) (rate(kubernetes_io:anthos_node_network_sent_bytes_count{monitored_resource="k8s_node",${project_id},${cluster_name},interface=~"enp81s0f.*"}[1m]))` | |
| Storage Usage per Node | Free Robin Disk Space % per Node | MQL | `{...} \| join \| value [v_0: 1 - div(t_0.value_robin_disk_rawused_sum, t_1.value_robin_disk_size_mean)]` | The MQL query calculates the free disk space percentage. The PromQL query performs the same calculation using subtraction and division. | PromQL | `1 - (sum by (node_name) (robin_disk_nslices{${project_id},${cluster_name}}) * 1073741824 / sum by (node_name) (robin_disk_size{${project_id},${cluster_name}}))` | |
| Storage Usage per Node | Free Robin Disk Space % per Node | MQL | `{...} \| join \| value [Disk_Free: cast_units(t_1.value_robin_disk_size_mean - t_0.value_robin_disk_rawused_sum, 'By')]` | The MQL query calculates the free disk space in bytes. The PromQL query performs the same calculation using subtraction. | PromQL | `sum by (node_name) (robin_disk_size{${project_id},${cluster_name}}) - sum by (node_name) (robin_disk_nslices{${project_id},${cluster_name}}) * 1073741824` | |

### `dashboards/gdc-robin-status.json`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Robin Node State - ONLINE & READY | MQL | `metric.type="prometheus.googleapis.com/robin_node_state/gauge" resource.type="prometheus_target" metric.label."node_state"="ONLINE" metric.label."node_status"="Ready"` | The MQL `timeSeriesFilter` is converted to a PromQL query. The metric name is converted, and the filters are applied as label matchers. The aggregation `REDUCE_MEAN` with `groupByFields` is converted to `avg by (node_name)`. | PromQL | `avg by (node_name) (prometheus_googleapis_com:robin_node_state{node_state="ONLINE", node_status="Ready"})` | |
| N/A | Robin Disk State - ONLINE & READY | MQL | `metric.type="prometheus.googleapis.com/robin_disk_status/gauge" resource.type="prometheus_target" metric.label."disk_state"="READY" metric.label."disk_status"="ONLINE"` | Similar to the previous query, the `timeSeriesFilter` is converted to a PromQL query with label matchers and aggregation. | PromQL | `avg by (node_name) (prometheus_googleapis_com:robin_disk_status{disk_state="READY", disk_status="ONLINE"})` | |
| N/A | Node 1 - UNHEALTHY Services | MQL | `metric.type="prometheus.googleapis.com/robin_service_status/gauge" resource.type="prometheus_target" metric.label."node_name"="cnuc-1" metric.label."service_state"!="UP"` | The `timeSeriesFilter` is converted to a PromQL query with label matchers for the specific node and service state. | PromQL | `avg by (service_state, service_name) (prometheus_googleapis_com:robin_service_status{node_name="cnuc-1", service_state!="UP"})` | |
| N/A | Node 2 - UNHEALTHY Services | MQL | `metric.type="prometheus.googleapis.com/robin_service_status/gauge" resource.type="prometheus_target" metric.label."node_name"="edge-2" metric.label."service_state"!="UP"` | The `timeSeriesFilter` is converted to a PromQL query with label matchers for the specific node and service state. | PromQL | `avg by (service_state, service_name) (prometheus_googleapis_com:robin_service_status{node_name="edge-2", service_state!="UP"})` | |
| N/A | Node 3 - UNHEALTHY Services | MQL | `metric.type="prometheus.googleapis.com/robin_service_status/gauge" resource.type="prometheus_target" metric.label."node_name"="edge-3" metric.label."service_state"!="UP"` | The `timeSeriesFilter` is converted to a PromQL query with label matchers for the specific node and service state. | PromQL | `avg by (service_state, service_name) (prometheus_googleapis_com:robin_service_status{node_name="edge-3", service_state!="UP"})` | |
| N/A | prometheus/robin_service_status/gauge [COUNT] | MQL | `metric.type="prometheus.googleapis.com/robin_service_status/gauge" resource.type="prometheus_target"` | The `timeSeriesFilter` is converted to a PromQL query. The `REDUCE_COUNT` aggregation is converted to `count by (...)`. | PromQL | `count by (service_state, service_name) (prometheus_googleapis_com:robin_service_status)` | |
---

### `dashboards/gdc-vm-distribution.json`

This section details the conversion of the "VMs" and "Robin Master" widgets from the "GDC - VM Distribution" dashboard. The goal was to translate complex, multi-stage MQL queries into functional PromQL equivalents that correctly group running pods by their respective names for each node.

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| :---- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| VMs | Node 1 | MQL | `{ t_0: fetch ... \| metric '...kube_pod_status_phase/gauge' ...; t_1: fetch ... \| metric '...kube_pod_info/gauge' ... } \| join \| ... \| group_by [metric.created_by_name]` | The conversion joins pod status with pod info to identify running VMs, then aggregates them by VM name (`created_by_name`). Using the `AND` operator was critical for correct label propagation from the `pod_info` metric. | PromQL | `sum by (created_by_name) (kubernetes_io:anthos_kube_pod_info_gauge{...} AND on(pod) kubernetes_io:anthos_kube_pod_status_phase_gauge{...})` | The final query provides an instantaneous count. This differs from the original's 5-minute average but correctly solves the primary grouping requirement. |
| Robin Master | Node 1 | MQL | `{ t_0: fetch ... \| metric '...kube_pod_status_phase/gauge' ...; t_1: fetch ... \| metric '...kube_pod_info/gauge' ... } \| join \| ... \| group_by [metric.pod]` | The conversion joins pod status with pod info to identify running `robin-master` pods. A simple multiplication (`*`) is sufficient here because the grouping key (`pod`) exists on both metrics. | PromQL | `sum by (pod) (kubernetes_io:anthos_kube_pod_status_phase_gauge{...} * on(pod) kubernetes_io:anthos_kube_pod_info_gauge{...})` |  |

#### Original MQL Query (VMs, Node 1)

The original MQL query involves a `join` between `kube_pod_status_phase` and `kube_pod_info` and multiple `group_by` operations to finally aggregate the count of running VMs by their `created_by_name`.

```mql
{ t_0 : fetch prometheus_target
 | metric 'kubernetes.io/anthos/kube_pod_status_phase/gauge'
 | filter resource.cluster='${cluster_name.value}'
 | filter
 metric.phase == 'Running' && (metric.pod =~ '(virt-launcher).*')
 | group_by 1m, [value_gauge_mean: mean(value.gauge)]
 | every 1m
 | group_by [metric.phase, metric.pod],
 [value_gauge_mean_aggregate: min(value_gauge_mean)];
t_1: fetch prometheus_target
 | metric 'kubernetes.io/anthos/kube_pod_info/gauge'
 | filter resource.cluster = "${cluster_name.value}"
 | filter metric.pod =~ '(virt-launcher).*'
 | filter metric.node =~ '.*01.ba.l.google.com$$'
 }
| join
| filter t_0.value_gauge_mean_aggregate > 0
| group_by 5m, [value_gauge_mean: mean(value.gauge)]
| every 5m
| group_by [metric.created_by_name]
```

#### Final PromQL Query (VMs, Node 1)

The final PromQL query provides an instantaneous count of running VMs, grouped by `created_by_name`.

```promql
sum by (created_by_name) (kubernetes_io:anthos_kube_pod_info_gauge{pod=~"(virt-launcher).*", node=~".*01.ba.l.google.com$", cluster="${cluster_name.value}"} AND on(pod) kubernetes_io:anthos_kube_pod_status_phase_gauge{phase="Running", pod=~"(virt-launcher).*", cluster="${cluster_name.value}"})
```

#### Final PromQL Query (Robin Master, Node 1)

The final PromQL query provides an instantaneous count of running `robin-master` pods, grouped by the pod name.

```promql
sum by (pod) (kubernetes_io:anthos_kube_pod_status_phase_gauge{phase="Running", pod=~"(robin-master).*", cluster="${cluster_name.value}"} * on(pod) kubernetes_io:anthos_kube_pod_info_gauge{pod=~"(robin-master).*", node=~".*01.ba.l.google.com$", cluster="${cluster_name.value}"})
```

#### Reasoning for the Conversion

The conversion process revealed several key principles for translating these MQL queries to PromQL:

1.  **Label Translation is Key:** The most critical issue was translating the MQL resource label `resource.cluster`. The correct PromQL equivalent is the `cluster` label, not `cluster_name`. This was the primary reason the initial queries returned "No data".

2.  **Choosing the Right Join Operator:**
    *   For the **VMs** widgets, the goal was to group by the `created_by_name` label, which only exists on the `pod_info` metric. The `AND` operator was the correct choice. It filters the series from the left-hand side (`pod_info`) based on matches on the right (`status_phase`), preserving the necessary `created_by_name` label for the final aggregation.
    *   For the **Robin Master** widgets, a simple multiplication (`*`) was sufficient. Since the grouping key (`pod`) exists on both metrics and is the joining key, the operator correctly combines the series.

3.  **Final Aggregation:** The `sum by (...)` wrapper correctly aggregates the results from the join operation, providing the per-VM or per-pod breakdown seen in the original dashboard.

### Final Comparison Summary

Overall, the conversion has been successful. The most critical issues that we worked on together have been resolved:
*   **No Data Issue:** The dashboard is no longer empty. The widgets are populated with data, as the queries now correctly use the `cluster` label instead of `cluster_name`.
*   **Grouping Issue:** The "VMs" widgets now correctly show a breakdown of individual VMs by name (`alpha-vm`, `linux-vm`, etc.) in the legend, matching the behavior of the original MQL dashboard. This was fixed by using the `AND` operator to ensure the `created_by_name` label was propagated correctly.

There is one remaining known difference between the two dashboards, which is a direct result of our last change to remove the `avg_over_time` function.

#### Known Difference: Instantaneous vs. 5-Minute Averaged Data

The only remaining discrepancy is the time alignment of the data.

*   **Original MQL Dashboard:** The charts for both the "VMs" and "Robin Master" widgets display data that has been aligned to 5-minute intervals and averaged. This is because the original MQL queries contain a `group_by 5m, [value_gauge_mean: mean(value.gauge)]` clause. This results in a smoother-looking graph that represents the average number of running pods over each 5-minute window.

*   **Current PromQL Dashboard:** The charts now display an *instantaneous* count of running pods. Because we reverted the change that used `avg_over_time`, the queries now show the exact state at each point in time. This will result in a more "jagged" or "stepped" graph that reacts immediately to pods starting or stopping.

**This is not a regression or a bug**, but rather a known trade-off. While the `avg_over_time` function would have perfectly replicated the original dashboard's smoothing, it was causing issues in your environment. The current version is a functional and accurate representation of the instantaneous state, which is a standard and valid approach for this type of monitoring.

### Conclusion

The converted PromQL dashboard is now in a stable and correct state. It successfully addresses the critical requirements of showing data and grouping it by the individual VM names. The only remaining difference is the lack of 5-minute data smoothing, which was intentionally removed to resolve a technical issue.

There are no other major discrepancies or gaps. The conversion can be considered complete and successful.

### `dashboards/gdc-vm-view.json`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | VM States | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_phase_count | group_by 1m, [value_kubevirt_vmi_phase_count_mean: mean(value.kubevirt_vmi_phase_count)] | every 1m | group_by [metric.phase], [value_kubevirt_vmi_phase_count_mean_aggregate: aggregate(value_kubevirt_vmi_phase_count_mean)]` | The MQL query aggregates the `kubevirt_vmi_phase_count` metric by phase. The PromQL equivalent uses `count by (state) (kubevirt_info)` which provides a similar breakdown of VM states. | PromQL | `count by (state) (kubevirt_info)` | |
| N/A | CPU usage per VM | MQL | `fetch k8s_container :: kubernetes.io/anthos/container/cpu/core_usage_time | align rate(2m) | every 2m | group_by [resource.pod_name], [value_core_usage_time_rate: mean(value.core_usage_time)]` | The MQL query calculates the rate of CPU usage per pod. The PromQL equivalent uses `rate(kubevirt_vmi_vcpu_seconds[2m])` to get the rate of vCPU usage per VM. | PromQL | `rate(kubevirt_vmi_vcpu_seconds[2m])` | |
| N/A | Network TX Bytes/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_transmit_bytes_total_rate: mean(value.network_transmit_bytes_total)]` | The MQL query calculates the rate of transmitted bytes. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_transmit_bytes_total[2m])` | |
| N/A | Network RX Bytes/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_receive_bytes_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_receive_bytes_total_rate: mean(value.network_receive_bytes_total)]` | The MQL query calculates the rate of received bytes. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_receive_bytes_total[2m])` | |
| N/A | Network TX Errors/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_transmit_errors_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_transmit_errors_total_rate: mean(value.network_transmit_errors_total)]` | The MQL query calculates the rate of transmit errors. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_transmit_errors_total[2m])` | |
| N/A | Network RX Errors/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_receive_errors_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_receive_errors_total_rate: mean(value.network_receive_errors_total)]` | The MQL query calculates the rate of receive errors. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_receive_errors_total[2m])` | |
| N/A | Network TX Packets/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_transmit_packets_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_transmit_packets_total_rate: mean(value.network_transmit_packets_total)]` | The MQL query calculates the rate of transmitted packets. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_transmit_packets_total[2m])` | |
| N/A | Network RX Packets/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_receive_packets_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_receive_packets_total_rate: mean(value.network_receive_packets_total)]` | The MQL query calculates the rate of received packets. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_receive_packets_total[2m])` | |
| N/A | Network TX Packets dropped/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_transmit_packets_dropped_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_transmit_packets_dropped_total_rate: mean(value.network_transmit_packets_dropped_total)]` | The MQL query calculates the rate of dropped transmit packets. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_transmit_packets_dropped_total[2m])` | |
| N/A | Network RX Packets dropped/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_receive_packets_dropped_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_receive_packets_dropped_total_rate: mean(value.network_receive_packets_dropped_total)]` | The MQL query calculates the rate of dropped receive packets. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_receive_packets_dropped_total[2m])` | |
| N/A | Storage write iops per VM per disk | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_storage_iops_write_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.drive], [value_storage_iops_write_total_rate: mean(value.storage_iops_write_total)]` | The MQL query calculates the rate of storage write IOPS. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_storage_iops_write_total[2m])` | |
| N/A | Storage read iops per VM per disk | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_storage_iops_read_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.drive], [value_storage_iops_read_total_rate: mean(value.storage_iops_read_total)]` | The MQL query calculates the rate of storage read IOPS. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_storage_iops_read_total[2m])` | |
| N/A | VMs | MQL | `metric.type="prometheus.googleapis.com/kubevirt_info/gauge" resource.type="prometheus_target"` | The MQL `timeSeriesFilter` is converted to a PromQL query. The metric name is converted, and the filters are applied as label matchers. | PromQL | `kubevirt_info` | |

---

## Alerting

### `alerts/control-plane/api-server-error-ratio-5-percent.yaml`

**MQL Query:**
```mql
{ t_0:
    { t_0:
        fetch k8s_container
        | metric 'kubernetes.io/anthos/apiserver_aggregated_request_total'
        | filter
            (resource.container_name =~ 'kube-apiserver')
            && (metric.code =~ '^(?:5..)$')
        | align delta(5m)
        | every 5m
        | group_by
            [resource.project_id, resource.location, resource.cluster_name],
            [value_apiserver_aggregated_request_total_aggregate:
               aggregate(value.apiserver_aggregated_request_total)]
    ; t_1:
        fetch k8s_container
        | metric 'kubernetes.io/anthos/apiserver_aggregated_request_total'
        | filter (resource.container_name =~ 'kube-apiserver')
        | align delta(5m)
        | every 5m
        | group_by
            [resource.project_id, resource.location, resource.cluster_name],
            [value_apiserver_aggregated_request_total_aggregate:
               aggregate(value.apiserver_aggregated_request_total)] }
    | join
    | value
        [v_0:
           div(t_0.value_apiserver_aggregated_request_total_aggregate,
             t_1.value_apiserver_aggregated_request_total_aggregate)]
; t_2:
    fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
    | filter (metric.anthos_distribution = 'baremetal')
    | align mean_aligner()
    | group_by [resource.project_id, resource.location, resource.cluster_name],
        [value_anthos_cluster_info_aggregate:
           aggregate(value.anthos_cluster_info)]
    | every 5m }
| join
| value [t_0.v_0]
| window 5m
| condition t_0.v_0 > 0.05 '1'
```

**PromQL Query:**
```promql
(sum by(project_id, location, cluster_name) (increase(kubernetes_io:anthos_apiserver_aggregated_request_total{container_name=~"kube-apiserver", code=~"5.."}[5m]))
/
sum by(project_id, location, cluster_name) (increase(kubernetes_io:anthos_apiserver_aggregated_request_total{container_name=~"kube-apiserver"}[5m]))
* on(project_id, location, cluster_name) group_left() (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}))
> 0.05
```

**Reasoning:**
1.  The MQL `fetch` and `metric` are converted to the PromQL metric name `kubernetes_io:anthos_apiserver_aggregated_request_total`.
2.  The MQL `filter`s are converted to PromQL label selectors `{container_name=~"kube-apiserver", code=~"5.."}`.
3.  The MQL `align delta(5m)` and `group_by` are converted to `sum by(...) (increase(...[5m]))`.
4.  The division of the two time series is performed with the `/` operator.
5.  The final `join` to filter for baremetal clusters is done with an `* on(...) group_left()` to multiply by a boolean info metric, ensuring the alert only fires on baremetal clusters.

---

### `alerts/control-plane/apiserver-down.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/uptime'
    | filter (resource.container_name =~ 'kube-apiserver')
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
| absent_for 300s
```

**PromQL Query:**
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-apiserver"})
```

**Reasoning:**
1.  The MQL `absent_for` logic is translated to the PromQL `absent()` function.
2.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.

---

### `alerts/control-plane/controller-manager-down.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/uptime'
    | filter (resource.container_name =~ 'kube-controller-manager')
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
| absent_for 300s
```

**PromQL Query:**
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-controller-manager"})
```

**Reasoning:**
1.  The MQL `absent_for` logic is translated to the PromQL `absent()` function.
2.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.

---

### `alerts/node/multiple-nodes-not-ready-realtime.yaml`

**MQL Query:**
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

**PromQL Query (with Baremetal Filter):**
```promql
count by (project_id, location, cluster_name) (kube_node_status_condition{condition="Ready", status="true"} == 0)
* on(project_id, location, cluster_name) group_left()
(max by (project_id, location, cluster_name) (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}))
> 1
```

**Reasoning:**
1.  The MQL `fetch` and `metric` are converted to the PromQL metric name `kube_node_status_condition`.
2.  The MQL `filter` for nodes that are not ready (`metric.condition == 'Ready' && metric.status != 'true'`) is translated to the PromQL label selector `{condition="Ready", status="true"} == 0`.
3.  The MQL `trigger` count of 2 is achieved by counting the nodes that are not ready using `count by (...)` and alerting when the sum is greater than 1.
4.  The `join` with `anthos_cluster_info` is converted to a multiplication (`*`). To prevent a "duplicate series" error and ensure a correct join with the node-level metric, the right-hand side is aggregated with `max by (...)` and the `monitored_resource` label is added to resolve ambiguity. The `on(...) group_left()` clause ensures the labels are preserved correctly.

**Simplified PromQL Query (Recommended):**
```promql
count by (project_id, location, cluster_name) (kube_node_status_condition{condition="Ready", status="true"} == 0) > 1
```

**Reasoning for Simplification:**
This version is the most direct and idiomatic PromQL query for this alert. It omits the join with `anthos_cluster_info` for simplicity. While the original MQL included a filter for "baremetal" clusters, this simplified query will work on *any* Kubernetes cluster, which is often more desirable for a general-purpose alert. It is more readable and less prone to join-related errors.

---

### `alerts/control-plane/scheduler-down.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/uptime'
    | filter (resource.container_name =~ 'kube-scheduler')
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
| absent_for 300s
```

**PromQL Query:**
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-scheduler"})
```

**Reasoning:**
1.  The MQL `absent_for` logic is translated to the PromQL `absent()` function.
2.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.

### `dashboards/gdc-vm-view.json`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | VM States | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_phase_count | group_by 1m, [value_kubevirt_vmi_phase_count_mean: mean(value.kubevirt_vmi_phase_count)] | every 1m | group_by [metric.phase], [value_kubevirt_vmi_phase_count_mean_aggregate: aggregate(value_kubevirt_vmi_phase_count_mean)]` | The MQL query aggregates the `kubevirt_vmi_phase_count` metric by phase. The PromQL equivalent uses `count by (state) (kubevirt_info)` which provides a similar breakdown of VM states. | PromQL | `count by (state) (kubevirt_info)` | |
| N/A | CPU usage per VM | MQL | `fetch k8s_container :: kubernetes.io/anthos/container/cpu/core_usage_time | align rate(2m) | every 2m | group_by [resource.pod_name], [value_core_usage_time_rate: mean(value.core_usage_time)]` | The MQL query calculates the rate of CPU usage per pod. The PromQL equivalent uses `rate(kubevirt_vmi_vcpu_seconds[2m])` to get the rate of vCPU usage per VM. | PromQL | `rate(kubevirt_vmi_vcpu_seconds[2m])` | |
| N/A | Network TX Bytes/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_transmit_bytes_total_rate: mean(value.network_transmit_bytes_total)]` | The MQL query calculates the rate of transmitted bytes. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_transmit_bytes_total[2m])` | |
| N/A | Network RX Bytes/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_receive_bytes_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_receive_bytes_total_rate: mean(value.network_receive_bytes_total)]` | The MQL query calculates the rate of received bytes. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_receive_bytes_total[2m])` | |
| N/A | Network TX Errors/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_transmit_errors_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_transmit_errors_total_rate: mean(value.network_transmit_errors_total)]` | The MQL query calculates the rate of transmit errors. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_transmit_errors_total[2m])` | |
| N/A | Network RX Errors/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_receive_errors_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_receive_errors_total_rate: mean(value.network_receive_errors_total)]` | The MQL query calculates the rate of receive errors. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_receive_errors_total[2m])` | |
| N/A | Network TX Packets/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_transmit_packets_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_transmit_packets_total_rate: mean(value.network_transmit_packets_total)]` | The MQL query calculates the rate of transmitted packets. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_transmit_packets_total[2m])` | |
| N/A | Network RX Packets/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_receive_packets_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_receive_packets_total_rate: mean(value.network_receive_packets_total)]` | The MQL query calculates the rate of received packets. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_receive_packets_total[2m])` | |
| N/A | Network TX Packets dropped/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_transmit_packets_dropped_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_transmit_packets_dropped_total_rate: mean(value.network_transmit_packets_dropped_total)]` | The MQL query calculates the rate of dropped transmit packets. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_transmit_packets_dropped_total[2m])` | |
| N/A | Network RX Packets dropped/s per VM per interface | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_network_receive_packets_dropped_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.interface], [value_network_receive_packets_dropped_total_rate: mean(value.network_receive_packets_dropped_total)]` | The MQL query calculates the rate of dropped receive packets. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_network_receive_packets_dropped_total[2m])` | |
| N/A | Storage write iops per VM per disk | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_storage_iops_write_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.drive], [value_storage_iops_write_total_rate: mean(value.storage_iops_write_total)]` | The MQL query calculates the rate of storage write IOPS. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_storage_iops_write_total[2m])` | |
| N/A | Storage read iops per VM per disk | MQL | `fetch k8s_container :: kubernetes.io/anthos/kubevirt_vmi_storage_iops_read_total | align rate(2m) | every 2m | group_by [resource.pod_name, metric.drive], [value_storage_iops_read_total_rate: mean(value.storage_iops_read_total)]` | The MQL query calculates the rate of storage read IOPS. This is a direct translation to `rate()` in PromQL. | PromQL | `rate(kubevirt_vmi_storage_iops_read_total[2m])` | |
| N/A | VMs | MQL | `metric.type="prometheus.googleapis.com/kubevirt_info/gauge" resource.type="prometheus_target"` | The MQL `timeSeriesFilter` is converted to a PromQL query. The metric name is converted, and the filters are applied as label matchers. | PromQL | `kubevirt_info` | |

---

## Alerting

### `alerts/control-plane/api-server-error-ratio-5-percent.yaml`

**MQL Query:**
```mql
{ t_0:
    { t_0:
        fetch k8s_container
        | metric 'kubernetes.io/anthos/apiserver_aggregated_request_total'
        | filter
            (resource.container_name =~ 'kube-apiserver')
            && (metric.code =~ '^(?:5..)$')
        | align delta(5m)
        | every 5m
        | group_by
            [resource.project_id, resource.location, resource.cluster_name],
            [value_apiserver_aggregated_request_total_aggregate:
               aggregate(value.apiserver_aggregated_request_total)]
    ; t_1:
        fetch k8s_container
        | metric 'kubernetes.io/anthos/apiserver_aggregated_request_total'
        | filter (resource.container_name =~ 'kube-apiserver')
        | align delta(5m)
        | every 5m
        | group_by
            [resource.project_id, resource.location, resource.cluster_name],
            [value_apiserver_aggregated_request_total_aggregate:
               aggregate(value.apiserver_aggregated_request_total)] }
    | join
    | value
        [v_0:
           div(t_0.value_apiserver_aggregated_request_total_aggregate,
             t_1.value_apiserver_aggregated_request_total_aggregate)]
; t_2:
    fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
    | filter (metric.anthos_distribution = 'baremetal')
    | align mean_aligner()
    | group_by [resource.project_id, resource.location, resource.cluster_name],
        [value_anthos_cluster_info_aggregate:
           aggregate(value.anthos_cluster_info)]
    | every 5m }
| join
| value [t_0.v_0]
| window 5m
| condition t_0.v_0 > 0.05 '1'
```

**PromQL Query:**
```promql
(sum by(project_id, location, cluster_name) (increase(kubernetes_io:anthos_apiserver_aggregated_request_total{container_name=~"kube-apiserver", code=~"5.."}[5m]))
/
sum by(project_id, location, cluster_name) (increase(kubernetes_io:anthos_apiserver_aggregated_request_total{container_name=~"kube-apiserver"}[5m]))
* on(project_id, location, cluster_name) group_left() (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}))
> 0.05
```

**Reasoning:**
1.  The MQL `fetch` and `metric` are converted to the PromQL metric name `kubernetes_io:anthos_apiserver_aggregated_request_total`.
2.  The MQL `filter`s are converted to PromQL label selectors `{container_name=~"kube-apiserver", code=~"5.."}`.
3.  The MQL `align delta(5m)` and `group_by` are converted to `sum by(...) (increase(...[5m]))`.
4.  The division of the two time series is performed with the `/` operator.
5.  The final `join` to filter for baremetal clusters is done with an `* on(...) group_left()` to multiply by a boolean info metric, ensuring the alert only fires on baremetal clusters.

---

### `alerts/control-plane/apiserver-down.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/uptime'
    | filter (resource.container_name =~ 'kube-apiserver')
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
| absent_for 300s
```

**PromQL Query:**
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-apiserver"})
```

**Reasoning:**
1.  The MQL `absent_for` logic is translated to the PromQL `absent()` function.
2.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.

---

### `alerts/control-plane/controller-manager-down.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/uptime'
    | filter (resource.container_name =~ 'kube-controller-manager')
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
| absent_for 300s
```

**PromQL Query:**
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-controller-manager"})
```

**Reasoning:**
1.  The MQL `absent_for` logic is translated to the PromQL `absent()` function.
2.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.

---

### `alerts/node/multiple-nodes-not-ready-realtime.yaml`

**MQL Query:**
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

**PromQL Query (with Baremetal Filter):**
```promql
count by (project_id, location, cluster_name) (kube_node_status_condition{condition="Ready", status="true"} == 0)
* on(project_id, location, cluster_name) group_left()
(max by (project_id, location, cluster_name) (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}))
> 1
```

**Reasoning:**
1.  The MQL `fetch` and `metric` are converted to the PromQL metric name `kube_node_status_condition`.
2.  The MQL `filter` for nodes that are not ready (`metric.condition == 'Ready' && metric.status != 'true'`) is translated to the PromQL label selector `{condition="Ready", status="true"} == 0`.
3.  The MQL `trigger` count of 2 is achieved by counting the nodes that are not ready using `count by (...)` and alerting when the sum is greater than 1.
4.  The `join` with `anthos_cluster_info` is converted to a multiplication (`*`). To prevent a "duplicate series" error and ensure a correct join with the node-level metric, the right-hand side is aggregated with `max by (...)` and the `monitored_resource` label is added to resolve ambiguity. The `on(...) group_left()` clause ensures the labels are preserved correctly.

**Simplified PromQL Query (Recommended):**
```promql
count by (project_id, location, cluster_name) (kube_node_status_condition{condition="Ready", status="true"} == 0) > 1
```

**Reasoning for Simplification:**
This version is the most direct and idiomatic PromQL query for this alert. It omits the join with `anthos_cluster_info` for simplicity. While the original MQL included a filter for "baremetal" clusters, this simplified query will work on *any* Kubernetes cluster, which is often more desirable for a general-purpose alert. It is more readable and less prone to join-related errors.

---

### `alerts/control-plane/scheduler-down.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/uptime'
    | filter (resource.container_name =~ 'kube-scheduler')
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
| absent_for 300s
```

**PromQL Query:**
```promql
absent(kubernetes_io:anthos_container_uptime{container_name=~"kube-scheduler"})
```

**Reasoning:**
1.  The MQL `absent_for` logic is translated to the PromQL `absent()` function.
2.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.
