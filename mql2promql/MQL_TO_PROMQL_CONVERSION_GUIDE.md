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

| File Path                                                  | Contains MQL? | Notes                                                                 | Convertion Status |
| :--------------------------------------------------------- | :------------ | :-------------------------------------------------------------------- | :---------------- |
| `alerts/control-plane/api-server-error-ratio-5-percent.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              | WIP               |
| `alerts/control-plane/apiserver-down.yaml`                 | Yes           | `conditionMonitoringQueryLanguage` used.                              | WIP               |
| `alerts/control-plane/controller-manager-down.yaml`        | Yes           | `conditionMonitoringQueryLanguage` used.                              | WIP               |
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
| `alerts/system/configsync-high-apply-duration-1h.yaml`     | No            | Uses `conditionPrometheusQueryLanguage`.                              | TBD               |
| `alerts/system/configsync-old-last-sync-2h.yaml`           | No            | Uses `conditionPrometheusQueryLanguage`.                              | TBD               |
| `alerts/system/coredns-down.yaml`                          | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/system/coredns-servfail-ratio-1-percent.yaml`      | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/system/externalsecrets-down-30m.yaml`              | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/system/externalsecrets-sync-error.yaml`            | No            | Uses `conditionPrometheusQueryLanguage`.                              | TBD               |
| `alerts/vm-workload/vmruntime-heartbeats-active-realtime.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-heartbeats-realtime.yaml`    | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-vm-down-5m.yaml`             | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-vm-missing-5m.yaml`          | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-vm-no-network-traffic-5m.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `dashboards/gdc-daily-report.json`                         | Yes (Partial) | Mixed MQL (`timeSeriesQueryLanguage`) and PromQL (`prometheusQuery`). | To be validated               |
| `dashboards/gdc-external-secrets.json`                     | No            | Uses `prometheusQuery`.                                               | TBD               |
| `dashboards/gdc-logs.json`                                 | No            | Log panel filters, not metric queries.                                | TBD               |
| `dashboards/gdc-node-view.json`                            | Yes           | Uses `timeSeriesQueryLanguage`.                                       | TBD               |
| `dashboards/gdc-robin-status.json`                         | Yes (Partial) | Mixed MQL (`timeSeriesFilter` with MQL-like filter) and PromQL.     | TBD               |
| `dashboards/gdc-vm-distribution.json`                      | Yes           | Uses `timeSeriesQueryLanguage`.                                       | TBD               |
| `dashboards/gdc-vm-view.json`                              | Yes (Partial) | Mixed MQL (`timeSeriesQueryLanguage`, `timeSeriesFilter`) and PromQL. | TBD               |

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

---

## Dashboards

### `dashboards/gdc-daily-report.json`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Availability | Node Availability | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/cpu/core_usage_time' \| ... \| join \| ...` | The MQL query calculates CPU utilization and then checks if it's greater than 0 to determine availability. The PromQL equivalent calculates the rate of CPU usage and checks if it's positive, grouped by node. | PromQL | `sum by (node_name) (rate(kubernetes_io:anthos_node_cpu_core_usage_time{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*"}[5m])) > 0` | The original MQL is complex for a simple availability check. A more direct PromQL query for node readiness would be `kubernetes_io:anthos_node_status_ready{...} == 1`. |
| Availability | VM Availability | MQL | `fetch k8s_container \| metric 'kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total' \| ... \| align rate(2m) \| ...` | The MQL query checks for network activity to determine VM availability. The PromQL query now correctly counts the number of available VMs. | PromQL | `count by (kubernetes_vmi_label_kubevirt_vm) (sum by (kubernetes_vmi_label_kubevirt_vm) (rate(kubernetes_io:anthos_kubevirt_vmi_network_transmit_bytes_total{monitored_resource="k8s_container",${cluster_name},cluster_name=~"${market.value}.*"}[2m])) > 0)` | |
| Peformance | Node CPU Utilization | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/cpu/allocatable_utilization' \| ... \| group_by 1m, [mean(...)] \| scale '%'` | The MQL query calculates the mean of a gauge metric over a 1-minute window. This is translated to `avg by (node_name) (avg_over_time(...))` in PromQL. The `scale '%' ` is converted to multiplication by 100. | PromQL | `avg by (node_name) (avg_over_time(kubernetes_io:anthos_node_cpu_allocatable_utilization{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*"}[1m])) * 100` | |
| Peformance | Node Memory Utilization | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/memory/allocatable_utilization' \| ... \| group_by [resource.node_name], ...` | This is similar to the CPU utilization query but adds a `group_by` for each node. This is translated to `avg by (node_name)` in PromQL. | PromQL | `avg by (node_name) (avg_over_time(kubernetes_io:anthos_node_memory_allocatable_utilization{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*"}[1m])) * 100` | |
| Peformance | Node Received Bytes | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/network/received_bytes_count' \| ... \| align rate(1m) \| ...` | The MQL query calculates the rate of received bytes. This is a direct translation to the `rate()` function in PromQL. | PromQL | `sum by (node_name) (rate(kubernetes_io:anthos_node_network_received_bytes_count{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*",interface=~"enp81s0f.*"}[1m]))` | The `unitOverride` was added to the JSON to ensure proper scaling. |
| Peformance | Node Sent Bytes | MQL | `fetch k8s_node \| metric 'kubernetes.io/anthos/node/network/sent_bytes_count' \| ... \| align rate(1m) \| ...` | Similar to the received bytes query, this calculates the rate of sent bytes. | PromQL | `sum by (node_name) (rate(kubernetes_io:anthos_node_network_sent_bytes_count{monitored_resource="k8s_node",${cluster_name},cluster_name=~"${market.value}.*",interface=~"enp81s0f.*"}[1m]))` | The `unitOverride` was added to the JSON to ensure proper scaling. |
| Peformance | VM CPU Utilization | MQL | `fetch k8s_container \| metric 'kubernetes.io/anthos/container/cpu/request_utilization' \| ... \| group_by [resource.pod_name], ...` | The MQL query calculates the average CPU utilization for VM pods. This is translated to `avg by (pod_name)` and `avg_over_time` in PromQL. | PromQL | `avg by (pod_name) (avg_over_time(kubernetes_io:anthos_container_cpu_request_utilization{monitored_resource="k8s_container",${cluster_name},cluster_name=~"${market.value}.*",pod_name=~"(virt-launcher).*",container_name="compute"}[1m])) * 100` | |
| Peformance | VM Memory Utilization | PromQL | `(1 - (sum by (pod_name) (avg_over_time(kubernetes_io:anthos_kubevirt_vmi_memory_unused_bytes{...}[2m])) / sum by (pod_name) (avg_over_time(kubernetes_io:anthos_container_memory_limit_bytes{...}[2m])))) * 100` | This widget already uses PromQL. | PromQL | `(1 - (sum by (pod_name) (avg_over_time(kubernetes_io:anthos_kubevirt_vmi_memory_unused_bytes{...}[2m])) / sum by (pod_name) (avg_over_time(kubernetes_io:anthos_container_memory_limit_bytes{...}[2m])))) * 100` | No conversion needed. |
| Peformance | VM Received Bytes (Per Interface) | MQL | `fetch k8s_container \| metric 'kubernetes.io/anthos/kubevirt_vmi_network_receive_bytes_total' \| align rate(1m) \| ...` | The MQL query calculates the rate of received bytes per VM and interface. This is translated to `rate()` and `sum by (...)` in PromQL. | PromQL | `sum by (kubernetes_vmi_label_kubevirt_vm, interface) (rate(kubernetes_io:anthos_kubevirt_vmi_network_receive_bytes_total{monitored_resource="k8s_container",${cluster_name},cluster_name=~"${market.value}.*"}[1m]))` | The `unitOverride` was added to the JSON to ensure proper scaling. |
| Peformance | VM Sent Bytes (Per Interface) | MQL | `fetch k8s_container \| metric 'kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total' \| align rate(1m) \| ...` | Similar to the VM received bytes query, this calculates the rate of sent bytes. | PromQL | `sum by (kubernetes_vmi_label_kubevirt_vm, interface) (rate(kubernetes_io:anthos_kubevirt_vmi_network_transmit_bytes_total{monitored_resource="k8s_container",${cluster_name},cluster_name=~"${market.value}.*"}[1m]))` | The `unitOverride` was added to the JSON to ensure proper scaling. |
| Peformance | Storage Write iops (Per VM) | PromQL | `sum by (kubernetes_vmi_label_kubevirt_vm)(rate(kubernetes_io:anthos_kubevirt_vmi_storage_iops_write_total{...}[2m]))` | This widget already uses PromQL. | PromQL | `sum by (kubernetes_vmi_label_kubevirt_vm)(rate(kubernetes_io:anthos_kubevirt_vmi_storage_iops_write_total{...}[2m]))` | No conversion needed. |
| Peformance | Storage Read iops (Per VM) | PromQL | `sum by (kubernetes_vmi_label_kubevirt_vm)(rate(kubernetes_io:anthos_kubevirt_vmi_storage_iops_read_total{...}[2m]))` | This widget already uses PromQL. | PromQL | `sum by (kubernetes_vmi_label_kubevirt_vm)(rate(kubernetes_io:anthos_kubevirt_vmi_storage_iops_read_total{...}[2m]))` | No conversion needed. |

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


