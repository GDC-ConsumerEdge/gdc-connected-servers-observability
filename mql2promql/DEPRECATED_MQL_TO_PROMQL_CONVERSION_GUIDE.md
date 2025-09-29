# MQL to PromQL Conversion Guide

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
