# MQL to PromQL Conversion Guide

This document lists Monitoring Query Language (MQL) queries found in the repository and provides proposed translations to Prometheus Query Language (PromQL).

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
| `dashboards/gdc-daily-report.json`                         | Yes (Partial) | Mixed MQL (`timeSeriesQueryLanguage`) and PromQL (`prometheusQuery`). | WIP               |
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
kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"} unless on(project_id, location, cluster_name) kubernetes_io:anthos_container_uptime{container_name=~"kube-apiserver"}
```

**Reasoning:**
1.  The MQL `absent_for` logic is best translated using the PromQL `unless` operator to avoid false positives.
2.  The left side of the `unless` operator selects all time series that identify a baremetal cluster via the `kubernetes_io:anthos_anthos_cluster_info` metric.
3.  The right side selects the `kubernetes_io:anthos_container_uptime` metric for the `kube-apiserver`.
4.  The `unless` operator returns a result only when a baremetal cluster exists on the left side but does *not* have a corresponding uptime metric on the right side, correctly identifying when the apiserver is down.
5.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.

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
kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"} unless on(project_id, location, cluster_name) kubernetes_io:anthos_container_uptime{container_name=~"kube-controller-manager"}
```

**Reasoning:**
1.  The MQL `absent_for` logic is best translated using the PromQL `unless` operator to avoid false positives.
2.  The left side of the `unless` operator selects all time series that identify a baremetal cluster via the `kubernetes_io:anthos_anthos_cluster_info` metric.
3.  The right side selects the `kubernetes_io:anthos_container_uptime` metric for the `kube-controller-manager`.
4.  The `unless` operator returns a result only when a baremetal cluster exists on the left side but does *not* have a corresponding uptime metric on the right side, correctly identifying when the controller manager is down.
5.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.

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

**PromQL Query:**
```promql
sum by (project_id, location, cluster_name) (kube_node_status_condition{condition="Ready", status="true"} == 0)
* on(project_id, location, cluster_name) group_left()
(max by (project_id, location, cluster_name) (kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"}))
> 1
```

**Reasoning:**
1.  The MQL `fetch` and `metric` are converted to the PromQL metric name `kube_node_status_condition`.
2.  The MQL `filter` for nodes that are not ready (`metric.condition == 'Ready' && metric.status != 'true'`) is translated to the PromQL label selector `{condition="Ready", status="true"} == 0`.
3.  The MQL `trigger` count of 2 is achieved by summing the nodes that are not ready and alerting when the sum is greater than 1.
4.  The `join` with `anthos_cluster_info` is converted to a multiplication (`*`). To prevent a "duplicate series" error, the right-hand side is aggregated with `max by (...)` to ensure a one-to-one match for each cluster. The `on(...) group_left()` clause ensures the labels are preserved correctly.

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
kubernetes_io:anthos_anthos_cluster_info{anthos_distribution="baremetal", monitored_resource="k8s_container"} unless on(project_id, location, cluster_name) kubernetes_io:anthos_container_uptime{container_name=~"kube-scheduler"}
```

**Reasoning:**
1.  The MQL `absent_for` logic is best translated using the PromQL `unless` operator to avoid false positives.
2.  The left side of the `unless` operator selects all time series that identify a baremetal cluster via the `kubernetes_io:anthos_anthos_cluster_info` metric.
3.  The right side selects the `kubernetes_io:anthos_container_uptime` metric for the `kube-scheduler`.
4.  The `unless` operator returns a result only when a baremetal cluster exists on the left side but does *not* have a corresponding uptime metric on the right side, correctly identifying when the scheduler is down.
5.  The `duration` of `300s` is applied to the alert policy itself, completing the `absent_for` logic.

---

## Dashboards

### `dashboards/gdc-daily-report.json`

**1. Widget: "Node Availability"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   { fetch k8s_node
     | metric 'kubernetes.io/anthos/node/cpu/core_usage_time'
   |  filter true()
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
     | group_by 1m, [value_core_usage_time_mean: mean(value.core_usage_time)]
     | every 1m
   ; fetch k8s_node
     | metric 'kubernetes.io/anthos/node/cpu/allocatable_cores'
   |  filter true()
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
     | group_by 1m, [value_allocatable_core_mean: mean(value.allocatable_cores)]
     | every 1m }
   | join
   | value [scaled_util: val(0) / val(1)]
   | condition val() > 0
   | group_by [resource.node_name], [value_has_cpu: aggregate(val(0))]
   ```
   **PromQL Query:**
   ```promql
    group by (node_name) (rate(kubernetes_io:anthos_node_cpu_core_usage_time{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node"}[1m]) / avg_over_time(kubernetes_io:anthos_node_cpu_allocatable_cores{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node"}[1m]) > 0)
   ```

**2. Widget: "VM Availability"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric 'kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | align rate(2m)
   | every 1m
   | group_by [metric.kubernetes_vmi_label_kubevirt_vm],
       [value_kubevirt_vmi_network_transmit_bytes_total:
          aggregate(value.kubevirt_vmi_network_transmit_bytes_total)]
   | condition value_kubevirt_vmi_network_transmit_bytes_total > cast_units(0, 'By/s')
   | val(0)
   ```
   **PromQL Query:**
   ```promql
   group by (kubernetes_vmi_label_kubevirt_vm) (rate(kubernetes_io:anthos_kubevirt_vmi_network_transmit_bytes_total{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_container"}[2m])) > 0
   ```

**3. Widget: "Node CPU Utilization"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/cpu/allocatable_utilization'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | group_by 1m,    [value_allocatable_utilization_mean: mean(value.allocatable_utilization)]
   | every 1m
   | scale '%'
   ```
   **PromQL Query:**
   ```promql
   avg by (node_name) (kubernetes_io:anthos_node_cpu_allocatable_utilization{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node"}) * 100
   ```

**4. Widget: "Node Memory Utilization"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/memory/allocatable_utilization'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | group_by 1m,
       [value_allocatable_utilization_mean: mean(value.allocatable_utilization)]
   | every 1m
   | group_by [resource.node_name],
       [value_allocatable_utilization_mean_aggregate:
          aggregate(value_allocatable_utilization_mean)]
   | scale '%'
   ```
   **PromQL Query:**
   ```promql
   avg by (node_name) (kubernetes_io:anthos_node_memory_allocatable_utilization{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node"}) * 100
   ```

**5. Widget: "Node Received Bytes"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/network/received_bytes_count'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | filter (metric.interface =~ 'enp81s0f.*')
   |align rate(1m)
   | every 1m
   | group_by [resource.node_name],
       [value_received_bytes_count_aggregate:
          aggregate(value.received_bytes_count)]
   ```
   **PromQL Query:**
   ```promql
   sum by (node_name) (rate(kubernetes_io:anthos_node_network_received_bytes_count{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node", interface=~"enp81s0f.*"}[1m]))
   ```

**6. Widget: "Node Sent Bytes"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/network/sent_bytes_count'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   |filter (metric.interface =~ 'enp81s0f.*')
   | align rate(1m)
   | every 1m
   | group_by [resource.node_name],
       [value_sent_bytes_count_aggregate:
          aggregate(value.sent_bytes_count)]
   ```
   **PromQL Query:**
   ```promql
   sum by (node_name) (rate(kubernetes_io:anthos_node_network_sent_bytes_count{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node", interface=~"enp81s0f.*"}[1m]))
   ```

**7. Widget: "VM CPU Utilization"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric 'kubernetes.io/anthos/container/cpu/request_utilization'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | filter resource.pod_name =~ '(virt-launcher).*' && resource.container_name == 'compute'
   | group_by [resource.pod_name], [value_request_utilization_mean: mean(value.request_utilization)]
   #| group_by [metadata.user.c'vm.kubevirt.io/name'], [value_request_utilization_mean: mean(value.request_utilization)]
   | every 1m
   | scale '%'
   ```
   **PromQL Query:**
   ```promql
   avg by (pod_name) (kubernetes_io:anthos_container_cpu_request_utilization{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_container", pod_name=~"(virt-launcher).*", container_name="compute"}) * 100
   ```

**8. Widget: "VM Received Bytes (Per Interface)"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric 'kubernetes.io/anthos/kubevirt_vmi_network_receive_bytes_total'
   | align rate(1m)
   | every 1m
   | group_by [metric.kubernetes_vmi_label_kubevirt_vm, metric.interface],
       [value_kubevirt_vmi_network_receive_bytes_total:
          aggregate(value.kubevirt_vmi_network_receive_bytes_total)]
   ```
   **PromQL Query:**
   ```promql
   sum by (kubernetes_vmi_label_kubevirt_vm, interface) (rate(kubernetes_io:anthos_kubevirt_vmi_network_receive_bytes_total{monitored_resource="k8s_container"}[1m]))
   ```

**9. Widget: "VM Sent Bytes (Per Interface)"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric 'kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total'
   | align rate(1m)
   | every 1m
   | group_by [metric.kubernetes_vmi_label_kubevirt_vm, metric.interface],
       [value_kubevirt_vmi_network_transmit_bytes_total:
          aggregate(value.kubevirt_vmi_network_transmit_bytes_total)]
   ```
   **PromQL Query:**
   ```promql
   sum by (kubernetes_vmi_label_kubevirt_vm, interface) (rate(kubernetes_io:anthos_kubevirt_vmi_network_transmit_bytes_total{monitored_resource="k8s_container"}[1m]))
   ```

---

## Dashboards

### `dashboards/gdc-daily-report.json`

**1. Widget: "Node Availability"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   { fetch k8s_node
     | metric 'kubernetes.io/anthos/node/cpu/core_usage_time'
   |  filter true()
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
     | group_by 1m, [value_core_usage_time_mean: mean(value.core_usage_time)]
     | every 1m
   ; fetch k8s_node
     | metric 'kubernetes.io/anthos/node/cpu/allocatable_cores'
   |  filter true()
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
     | group_by 1m, [value_allocatable_core_mean: mean(value.allocatable_cores)]
     | every 1m }
   | join
   | value [scaled_util: val(0) / val(1)]
   | condition val() > 0
   | group_by [resource.node_name], [value_has_cpu: aggregate(val(0))]
   ```
   **PromQL Query:**
   ```promql
    group by (node_name) (rate(kubernetes_io:anthos_node_cpu_core_usage_time{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node"}[1m]) / avg_over_time(kubernetes_io:anthos_node_cpu_allocatable_cores{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node"}[1m]) > 0)
   ```

**2. Widget: "VM Availability"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric 'kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | align rate(2m)
   | every 1m
   | group_by [metric.kubernetes_vmi_label_kubevirt_vm],
       [value_kubevirt_vmi_network_transmit_bytes_total:
          aggregate(value.kubevirt_vmi_network_transmit_bytes_total)]
   | condition value_kubevirt_vmi_network_transmit_bytes_total > cast_units(0, 'By/s')
   | val(0)
   ```
   **PromQL Query:**
   ```promql
   group by (kubernetes_vmi_label_kubevirt_vm) (rate(kubernetes_io:anthos_kubevirt_vmi_network_transmit_bytes_total{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_container"}[2m])) > 0
   ```

**3. Widget: "Node CPU Utilization"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/cpu/allocatable_utilization'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | group_by 1m,    [value_allocatable_utilization_mean: mean(value.allocatable_utilization)]
   | every 1m
   | scale '%'
   ```
   **PromQL Query:**
   ```promql
   avg by (node_name) (kubernetes_io:anthos_node_cpu_allocatable_utilization{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node"}) * 100
   ```

**4. Widget: "Node Memory Utilization"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/memory/allocatable_utilization'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | group_by 1m,
       [value_allocatable_utilization_mean: mean(value.allocatable_utilization)]
   | every 1m
   | group_by [resource.node_name],
       [value_allocatable_utilization_mean_aggregate:
          aggregate(value_allocatable_utilization_mean)]
   | scale '%'
   ```
   **PromQL Query:**
   ```promql
   avg by (node_name) (kubernetes_io:anthos_node_memory_allocatable_utilization{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node"}) * 100
   ```

**5. Widget: "Node Received Bytes"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/network/received_bytes_count'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | filter (metric.interface =~ 'enp81s0f.*')
   |align rate(1m)
   | every 1m
   | group_by [resource.node_name],
       [value_received_bytes_count_aggregate:
          aggregate(value.received_bytes_count)]
   ```
   **PromQL Query:**
   ```promql
   sum by (node_name) (rate(kubernetes_io:anthos_node_network_received_bytes_count{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node", interface=~"enp81s0f.*"}[1m]))
   ```

**6. Widget: "Node Sent Bytes"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/network/sent_bytes_count'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   |filter (metric.interface =~ 'enp81s0f.*')
   | align rate(1m)
   | every 1m
   | group_by [resource.node_name],
       [value_sent_bytes_count_aggregate:
          aggregate(value.sent_bytes_count)]
   ```
   **PromQL Query:**
   ```promql
   sum by (node_name) (rate(kubernetes_io:anthos_node_network_sent_bytes_count{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_node", interface=~"enp81s0f.*"}[1m]))
   ```

**7. Widget: "VM CPU Utilization"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric 'kubernetes.io/anthos/container/cpu/request_utilization'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | filter resource.pod_name =~ '(virt-launcher).*' && resource.container_name == 'compute'
   | group_by [resource.pod_name], [value_request_utilization_mean: mean(value.request_utilization)]
   #| group_by [metadata.user.c'vm.kubevirt.io/name'], [value_request_utilization_mean: mean(value.request_utilization)]
   | every 1m
   | scale '%'
   ```
   **PromQL Query:**
   ```promql
   avg by (pod_name) (kubernetes_io:anthos_container_cpu_request_utilization{${cluster_name}, cluster_name=~"${market.value}.*", monitored_resource="k8s_container", pod_name=~"(virt-launcher).*", container_name="compute"}) * 100
   ```

**8. Widget: "VM Received Bytes (Per Interface)"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric 'kubernetes.io/anthos/kubevirt_vmi_network_receive_bytes_total'
   | align rate(1m)
   | every 1m
   | group_by [metric.kubernetes_vmi_label_kubevirt_vm, metric.interface],
       [value_kubevirt_vmi_network_receive_bytes_total:
          aggregate(value.kubevirt_vmi_network_receive_bytes_total)]
   ```
   **PromQL Query:**
   ```promql
   sum by (kubernetes_vmi_label_kubevirt_vm, interface) (rate(kubernetes_io:anthos_kubevirt_vmi_network_receive_bytes_total{monitored_resource="k8s_container"}[1m]))
   ```

**9. Widget: "VM Sent Bytes (Per Interface)"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric 'kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total'
   | align rate(1m)
   | every 1m
   | group_by [metric.kubernetes_vmi_label_kubevirt_vm, metric.interface],
       [value_kubevirt_vmi_network_transmit_bytes_total:
          aggregate(value.kubevirt_vmi_network_transmit_bytes_total)]
   ```
   **PromQL Query:**
   ```promql
   sum by (kubernetes_vmi_label_kubevirt_vm, interface) (rate(kubernetes_io:anthos_kubevirt_vmi_network_transmit_bytes_total{monitored_resource="k8s_container"}[1m]))
   ```

---
This concludes the exhaustive list.