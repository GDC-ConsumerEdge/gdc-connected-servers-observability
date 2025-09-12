# MQL to PromQL Conversion Guide

This document lists Monitoring Query Language (MQL) queries found in the repository and provides proposed translations to Prometheus Query Language (PromQL).

## Summary of Files Containing MQL Queries

| File Path                                                  | Contains MQL? | Notes                                                                 |
| :--------------------------------------------------------- | :------------ | :-------------------------------------------------------------------- |
| `alerts/control-plane/api-server-error-ratio-5-percent.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/control-plane/apiserver-down.yaml`                 | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/control-plane/controller-manager-down.yaml`        | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/control-plane/scheduler-down.yaml`                 | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/node/multiple-nodes-not-ready-realtime.yaml`       | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/node/node-cpu-usage-high.yaml`                     | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/node/node-memory-usage-high.yaml`                  | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/node/node-not-ready-30m.yaml`                      | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/pods/pod-crash-looping.yaml`                       | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/pods/pod-not-ready-1h.yaml`                        | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/storage/robin-disk-inactive-10m.yaml`              | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/storage/robin-master-down-10m.yaml`                | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/storage/robin-node-offline-30m.json`               | Yes           | JSON format, uses `conditionThreshold` with MQL-like filter.        |
| `alerts/system/configsync-down-30m.yaml`                   | Yes           | `conditionAbsent` with MQL-like filter.                             |
| `alerts/system/configsync-high-apply-duration-1h.yaml`     | No            | Uses `conditionPrometheusQueryLanguage`.                              |
| `alerts/system/configsync-old-last-sync-2h.yaml`           | No            | Uses `conditionPrometheusQueryLanguage`.                              |
| `alerts/system/coredns-down.yaml`                          | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/system/coredns-servfail-ratio-1-percent.yaml`      | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/system/externalsecrets-down-30m.yaml`              | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/system/externalsecrets-sync-error.yaml`            | No            | Uses `conditionPrometheusQueryLanguage`.                              |
| `alerts/vm-workload/vmruntime-heartbeats-active-realtime.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/vm-workload/vmruntime-heartbeats-realtime.yaml`    | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/vm-workload/vmruntime-vm-down-5m.yaml`             | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/vm-workload/vmruntime-vm-missing-5m.yaml`          | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `alerts/vm-workload/vmruntime-vm-no-network-traffic-5m.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              |
| `dashboards/gdc-daily-report.json`                         | Yes (Partial) | Mixed MQL (`timeSeriesQueryLanguage`) and PromQL (`prometheusQuery`). |
| `dashboards/gdc-external-secrets.json`                     | No            | Uses `prometheusQuery`.                                               |
| `dashboards/gdc-logs.json`                                 | No            | Log panel filters, not metric queries.                                |
| `dashboards/gdc-node-view.json`                            | Yes           | Uses `timeSeriesQueryLanguage`.                                       |
| `dashboards/gdc-robin-status.json`                         | Yes (Partial) | Mixed MQL (`timeSeriesFilter` with MQL-like filter) and PromQL.     |
| `dashboards/gdc-vm-distribution.json`                      | Yes           | Uses `timeSeriesQueryLanguage`.                                       |
| `dashboards/gdc-vm-view.json`                              | Yes (Partial) | Mixed MQL (`timeSeriesQueryLanguage`, `timeSeriesFilter`) and PromQL. |

---

## Exhaustive List of MQL Queries and Proposed PromQL Translations

---

### File: `alerts/control-plane/api-server-error-ratio-5-percent.yaml`

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

**Proposed PromQL Translation:**
```promql
# Alert condition:
(
  sum by (project_id, location, cluster_name) (
    increase(kubernetes_io_anthos_apiserver_aggregated_request_total{container_name="kube-apiserver", code=~"5.."}[5m])
  )
  /
  sum by (project_id, location, cluster_name) (
    increase(kubernetes_io_anthos_apiserver_aggregated_request_total{container_name="kube-apiserver"}[5m])
  )
)
* on(project_id, location, cluster_name) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
> 0.05

# In Prometheus alert rule:
# alert: APIServerErrorRatioExceeds5Percent
# expr: (...) > 0.05 # as above
# for: 10m
# labels:
#   severity: critical
# annotations:
#   summary: API server error count ratio exceeds 5 percent
#   description: 'API server error count ratio: 500s error-response counts / all response counts is {{ $value }} for cluster {{ $labels.cluster_name }}.'
```

---

### File: `alerts/control-plane/apiserver-down.yaml`

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

**Proposed PromQL Translation:**
```promql
# Alert condition:
absent (
  kubernetes_io_anthos_container_uptime{container_name="kube-apiserver"}
  * on(project_id, location, cluster_name) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
)

# In Prometheus alert rule:
# alert: APIServerDown
# expr: absent(...) # as above
# for: 5m
# labels:
#   severity: critical
# annotations:
#   summary: API server down (critical)
#   description: 'API server has been down or missing for 5 minutes on cluster {{ $labels.cluster_name }}.'
```

---

### File: `alerts/control-plane/controller-manager-down.yaml`

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

**Proposed PromQL Translation:**
```promql
# Alert condition:
absent (
  kubernetes_io_anthos_container_uptime{container_name="kube-controller-manager"}
  * on(project_id, location, cluster_name) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
)

# In Prometheus alert rule:
# alert: ControllerManagerDown
# expr: absent(...) # as above
# for: 5m
# labels:
#   severity: critical
# annotations:
#   summary: Controller manager down (critical)
#   description: 'Controller manager has been down or missing for 5 minutes on cluster {{ $labels.cluster_name }}.'
```

---

### File: `alerts/control-plane/scheduler-down.yaml`

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

**Proposed PromQL Translation:**
```promql
# Alert condition:
absent (
  kubernetes_io_anthos_container_uptime{container_name="kube-scheduler"}
  * on(project_id, location, cluster_name) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
)

# In Prometheus alert rule:
# alert: SchedulerDown
# expr: absent(...) # as above
# for: 5m
# labels:
#   severity: critical
# annotations:
#   summary: Scheduler down (critical)
#   description: 'Scheduler has been down or missing for 5 minutes on cluster {{ $labels.cluster_name }}.'
```

---

### File: `alerts/node/multiple-nodes-not-ready-realtime.yaml`

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

**Proposed PromQL Translation:**
```promql
# Alert condition (count of not-ready nodes):
sum by (project_id, location, cluster) (
  kube_node_status_condition{condition="Ready", status="true"} == 0
)
* on(project_id, location, cluster) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
> 1

# In Prometheus alert rule:
# alert: MultipleNodesNotReady
# expr: sum by (project_id, location, cluster) (kube_node_status_condition{condition="Ready", status="true"} == 0) * on(project_id, location, cluster) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1) > 1
# for: 2m
# labels:
#   severity: critical
# annotations:
#   summary: Multiple nodes not ready (critical)
#   description: '{{ $value }} nodes are not ready in cluster {{ $labels.cluster }}.'
```

---

### File: `alerts/node/node-cpu-usage-high.yaml`

**MQL Query:**
```mql
{ t_0:
    { t_0:
        fetch prometheus_target
        | metric 'kubernetes.io/anthos/kube_node_status_allocatable/gauge'
        | filter (metric.resource == 'cpu')
        | group_by [metric.node, resource.cluster, resource.location, resource.project_id],
            [value_kube_node_status_allocatable_mean: mean(value.gauge)]
        | every 1m
    ; t_1:
        fetch prometheus_target
        | metric 'kubernetes.io/anthos/kube_node_status_capacity/gauge'
        | filter (metric.resource == 'cpu')
        | group_by [metric.node, resource.cluster, resource.location, resource.project_id],
            [value_kube_node_status_capacity_mean: mean(value.gauge)]
        | every 1m }
    | join
    | value
        [v_0: div(t_0.value_kube_node_status_allocatable_mean, t_1.value_kube_node_status_capacity_mean)]
; t_2:
    fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
    | filter (metric.anthos_distribution = 'baremetal')
    | align mean_aligner()
    | group_by [resource.project_id, resource.location, cluster: resource.cluster_name],
        [value_anthos_cluster_info_aggregate: aggregate(value.anthos_cluster_info)]
    | every 1m }
| join
| window 1m
| value [t_0.v_0]
| condition t_0.v_0 < 0.2 '1'
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
(
  sum by (node, cluster, location, project_id) (
    kubernetes_io_anthos_kube_node_status_allocatable_gauge{resource="cpu"}
  )
  /
  sum by (node, cluster, location, project_id) (
    kubernetes_io_anthos_kube_node_status_capacity_gauge{resource="cpu"}
  )
)
* on(project_id, location, cluster) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
< 0.2

# In Prometheus alert rule:
# alert: NodeLowAllocatableCPUPercent
# expr: (...) < 0.2 # as above
# for: 10m
# labels:
#   severity: critical
# annotations:
#   summary: Node allocatable CPU percent is less than 20% (critical)
#   description: 'Node {{ $labels.node }} in cluster {{ $labels.cluster }} has allocatable CPU {{ $value | humanizePercentage }} of capacity.'
```

---

### File: `alerts/node/node-memory-usage-high.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch prometheus_target
    | metric 'kubernetes.io/anthos/node_memory_MemAvailable_bytes/gauge'
    | group_by [resource.cluster, resource.instance, resource.location, resource.project_id],
        [value_node_memory_MemAvailable_bytes_mean: mean(value.gauge)]
    | every 1m
; t_1:
    fetch prometheus_target
    | metric 'kubernetes.io/anthos/node_memory_MemTotal_bytes/gauge'
    | group_by [resource.instance, resource.cluster, resource.project_id, resource.location],
        [value_node_memory_MemTotal_bytes_mean: mean(value.gauge)]
    | every 1m
}
| join
| value [v_0: div(t_0.value_node_memory_MemAvailable_bytes_mean, t_1.value_node_memory_MemTotal_bytes_mean)]
| window 1m
| condition v_0 < 0.2 '1'
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
(
  sum by (cluster, instance, location, project_id) (
    kubernetes_io_anthos_node_memory_MemAvailable_bytes_gauge
  )
  /
  sum by (cluster, instance, location, project_id) (
    kubernetes_io_anthos_node_memory_MemTotal_bytes_gauge
  )
) < 0.2

# In Prometheus alert rule:
# alert: NodeMemoryUsageHigh
# expr: (...) < 0.2 # as above
# for: 10m
# labels:
#   severity: critical
# annotations:
#   summary: Node memory usage exceeds 80 percent (critical)
#   description: 'Node {{ $labels.instance }} in cluster {{ $labels.cluster }} has available memory {{ $value | humanizePercentage }} of total. Usage is > 80%.'
```

---

### File: `alerts/node/node-not-ready-30m.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch prometheus_target
    | metric 'kubernetes.io/anthos/kube_node_status_condition/gauge'
    | filter (metric.condition != 'Ready' && metric.status == 'true')
    | group_by [resource.project_id, resource.location, resource.cluster],
        [value_kube_node_status_condition_mean: mean(value.gauge)]
    | every 1m
; t_1:
    fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
    | filter (metric.anthos_distribution = 'baremetal')
    | align mean_aligner()
    | group_by [resource.project_id, resource.location, cluster: resource.cluster_name],
        [value_anthos_cluster_info_aggregate: aggregate(value.anthos_cluster_info)]
    | every 1m }
| join
| value [t_0.value_kube_node_status_condition_mean]
| window 1m
| condition t_0.value_kube_node_status_condition_mean > 0 '1'
```

**Proposed PromQL Translation:**
```promql
# Alert condition (any node not Ready):
(sum by (project_id, location, cluster) (
  kube_node_status_condition{condition="Ready", status="true"} == 0
)
* on(project_id, location, cluster) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
) > 0

# In Prometheus alert rule:
# alert: NodeNotReadyFor30m
# expr: (...) > 0 # as above
# for: 30m
# labels:
#   severity: critical
# annotations:
#   summary: Node not ready for more than 30 minutes (critical)
#   description: 'At least one node in cluster {{ $labels.cluster }} has been not Ready for more than 30 minutes.'
```

---

### File: `alerts/pods/pod-crash-looping.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch prometheus_target
    | metric 'kubernetes.io/anthos/kube_pod_container_status_restarts_total/counter'
    | filter (metric.pod !~ '^(bm-system|robin-prejob).*')
    | align delta(15m)
    | every 15m
    | group_by
        [resource.project_id, resource.location, resource.cluster,
         resource.namespace, metric.container],
        [value_kube_pod_container_status_restarts_total_aggregate:
           aggregate(value.counter)]
; t_1:
    fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
    | filter (metric.anthos_distribution = 'baremetal')
    | align mean_aligner()
    | group_by [resource.project_id, resource.location, cluster: resource.cluster_name],
        [value_anthos_cluster_info_aggregate:
           aggregate(value.anthos_cluster_info)]
    | every 15m }
| join
| value [t_0.value_kube_pod_container_status_restarts_total_aggregate]
| window 15m
| condition t_0.value_kube_pod_container_status_restarts_total_aggregate > 0 '1'
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
(increase(kube_pod_container_status_restarts_total{pod!~"^(bm-system|robin-prejob).*"}[15m]) > 0)
* on(project_id, location, cluster) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)

# In Prometheus alert rule:
# alert: PodCrashLooping
# expr: (increase(kube_pod_container_status_restarts_total{pod!~"^(bm-system|robin-prejob).*"}[15m]) > 0) * on(project_id, location, cluster) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
# for: 1m
# labels:
#   severity: critical
# annotations:
#   summary: Pod crash looping (critical)
#   description: 'Pod {{ $labels.pod }} container {{ $labels.container }} in namespace {{ $labels.namespace }} cluster {{ $labels.cluster }} is crash looping. Restarts in last 15m: {{ $value }}.'
```

---

### File: `alerts/pods/pod-not-ready-1h.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch prometheus_target
    | metric 'kubernetes.io/anthos/kube_pod_status_phase/gauge'
    | filter (metric.phase =~ 'Pending|Unknown|Failed')
    | filter (metric.pod !~ '^(bm-system||robin-prejob).*')
    | group_by [resource.project_id, resource.location, resource.cluster,
         resource.namespace, metric.pod],
        [value_kube_pod_status_phase_mean: mean(value.gauge)]
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
| value [t_0.value_kube_pod_status_phase_mean]
| window 1m
| condition t_0.value_kube_pod_status_phase_mean > 0 '1'
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
(kube_pod_status_phase{phase=~"Pending|Unknown|Failed", pod!~"^(bm-system|robin-prejob).*" } == 1)
* on(project_id, location, cluster) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)

# In Prometheus alert rule:
# alert: PodNotReadyFor1h
# expr: (kube_pod_status_phase{phase=~"Pending|Unknown|Failed", pod!~"^(bm-system|robin-prejob).*" } == 1) * on(project_id, location, cluster) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
# for: 1h
# labels:
#   severity: critical
# annotations:
#   summary: Pod not ready for more than one hour (critical)
#   description: 'Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} cluster {{ $labels.cluster }} has been in phase {{ $labels.phase }} for more than one hour.'
```

---

### File: `alerts/storage/robin-disk-inactive-10m.yaml`

**MQL Query:**
```mql
fetch prometheus_target
| metric 'prometheus.googleapis.com/robin_disk_status/gauge'
| group_by 1m, [value_robin_disk_status_mean: mean(value.robin_disk_status)]
| every 1m
| group_by [metric.disk_wwn, metric.disk_state],
    [value_robin_disk_status_mean_mean: mean(value_robin_disk_status_mean)]
| condition val() < 1 '1'
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
robin_disk_status_gauge < 1

# In Prometheus alert rule:
# alert: RobinDiskInactive
# expr: robin_disk_status_gauge < 1
# for: 5m
# labels:
#   severity: critical
#   disk_wwn: '{{ $labels.disk_wwn }}'
#   disk_state: '{{ $labels.disk_state }}'
# annotations:
#   summary: Robin disk no status for more than 5 minutes (critical)
#   description: 'Robin disk WWN {{ $labels.disk_wwn }} (state: {{ $labels.disk_state }}) has had no status (or status < 1) for more than 5 minutes.'
```

---

### File: `alerts/storage/robin-master-down-10m.yaml`

**MQL Query:**
```mql
fetch prometheus_target
| metric 'prometheus.googleapis.com/robin_node_state/gauge'
| filter (metric.node_role == 'MANAGER_MASTER')
| group_by 10m,
   [value_robin_node_state_aggregate: aggregate(value.robin_node_state)]
| every 10m
| group_by [], [row_count: row_count()]
| condition val() < 1 '1'
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
sum(robin_node_state_gauge{node_role="MANAGER_MASTER"}) < 1

# In Prometheus alert rule:
# alert: RobinMasterDown
# expr: sum(robin_node_state_gauge{node_role="MANAGER_MASTER"}) < 1
# for: 10m
# labels:
#   severity: critical
# annotations:
#   summary: Robin master not online for more than 10 minutes (critical)
#   description: 'There are no online Robin masters (node_role="MANAGER_MASTER") for more than 10 minutes. Current count: {{ $value }}.'
```

---

### File: `alerts/storage/robin-node-offline-30m.json` (JSON format)

**MQL-like Filter (`conditionThreshold.filter`):**
```
resource.type = "prometheus_target" AND metric.type = "prometheus.googleapis.com/robin_node_state/gauge"
```
**Aggregations:** AlignmentPeriod: "1800s", crossSeriesReducer: "REDUCE_MEAN", groupByFields: ["metric.label.service_name", "metric.label.node_name"], perSeriesAligner: "ALIGN_MEAN". Comparison: "COMPARISON_LT", thresholdValue: 1.

**Proposed PromQL Translation:**
```promql
# Alert condition:
avg_over_time(robin_node_state_gauge[30m]) < 1

# In Prometheus alert rule:
# alert: RobinNodeNotOnline30m
# expr: avg_over_time(robin_node_state_gauge[30m]) < 1
# for: 1m
# labels:
#   severity: critical
#   node_name: '{{ $labels.node_name }}'
#   service_name: '{{ $labels.service_name }}'
# annotations:
#   summary: Robin node not online for 30 minutes
#   description: 'Robin node {{ $labels.node_name }} (service: {{ $labels.service_name }}) has an average state < 1 over the last 30 minutes (value: {{ $value }}), indicating it was not consistently online.'
```

---

### File: `alerts/system/configsync-down-30m.yaml`

**MQL-like Filter (from `conditionAbsent.filter`):**
```
resource.type = "k8s_container" AND metric.type = "external.googleapis.com/prometheus/config_sync_resource_count"
```
**Condition Absent:** duration: 1800s, aggregations: alignmentPeriod: 300s, perSeriesAligner: ALIGN_MEAN.

**Proposed PromQL Translation:**
```promql
# Alert condition:
absent(avg_over_time(external_googleapis_com_prometheus_config_sync_resource_count[5m]))

# In Prometheus alert rule:
# alert: ConfigSyncDown30m
# expr: absent(avg_over_time(external_googleapis_com_prometheus_config_sync_resource_count[5m]))
# for: 30m
# labels:
#   severity: critical
# annotations:
#   summary: ConfigSync down for 30 minutes (critical)
#   description: 'The metric external.googleapis.com/prometheus/config_sync_resource_count (averaged over 5m) has been absent for 30 minutes, indicating ConfigSync might be down.'
```

---
### File: `alerts/system/coredns-down.yaml`

**MQL Query:**
```mql
{ t_0:
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/uptime'
    | filter (resource.container_name =~ 'coredns')
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

**Proposed PromQL Translation:**
```promql
# Alert condition:
absent (
  kubernetes_io_anthos_container_uptime{container_name=~"coredns"}
  * on(project_id, location, cluster_name) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
)

# In Prometheus alert rule:
# alert: CoreDNSDown
# expr: absent(...) # as above
# for: 5m
# labels:
#   severity: critical
# annotations:
#   summary: CoreDNS down (critical)
#   description: 'CoreDNS has been down or missing for 5 minutes on cluster {{ $labels.cluster_name }}.'
```

---

### File: `alerts/system/coredns-servfail-ratio-1-percent.yaml`

**MQL Query:**
```mql
{ t_0:
    { t_0:
        fetch k8s_container
        | metric 'kubernetes.io/anthos/coredns_dns_responses_total'
        | filter (metric.rcode == 'SERVFAIL')
        | align delta(5m)
        | every 5m
        | group_by
            [resource.project_id, resource.location, resource.cluster_name],
            [value_coredns_dns_responses_total_aggregate:
               aggregate(value.coredns_dns_responses_total)]
    ; t_1:
        fetch k8s_container
        | metric 'kubernetes.io/anthos/coredns_dns_responses_total'
        | align delta(5m)
        | every 5m
        | group_by
            [resource.project_id, resource.location, resource.cluster_name],
            [value_coredns_dns_responses_total_aggregate:
               aggregate(value.coredns_dns_responses_total)] }
    | join
    | value
        [v_0:
           div(t_0.value_coredns_dns_responses_total_aggregate,
             t_1.value_coredns_dns_responses_total_aggregate)]
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
| condition t_0.v_0 > 0.01 '1'
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
(
  sum by (project_id, location, cluster_name) (
    increase(kubernetes_io_anthos_coredns_dns_responses_total{rcode="SERVFAIL"}[5m])
  )
  /
  sum by (project_id, location, cluster_name) (
    increase(kubernetes_io_anthos_coredns_dns_responses_total[5m])
  )
)
* on(project_id, location, cluster_name) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
> 0.01

# In Prometheus alert rule:
# alert: CoreDNSServfailRatioExceeds1Percent
# expr: (...) > 0.01 # as above
# for: 10m
# labels:
#   severity: warning
# annotations:
#   summary: CoreDNS SERVFAIL count ratio exceeds 1 percent
#   description: 'CoreDNS SERVFAIL ratio is {{ $value | humanizePercentage }} on cluster {{ $labels.cluster_name }}.'
```

---

### File: `alerts/system/externalsecrets-down-30m.yaml`

**MQL Query:**
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

**Proposed PromQL Translation:**
```promql
# Alert condition:
absent (
  kubernetes_io_anthos_container_uptime{container_name=~"external-secrets"}
  * on(project_id, location, cluster_name) group_left(anthos_distribution) (anthos_cluster_info{anthos_distribution="baremetal"} == 1)
)

# In Prometheus alert rule:
# alert: ExternalSecretsDown
# expr: absent(...) # as above
# for: 30m
# labels:
#   severity: critical
# annotations:
#   summary: External Secrets down (critical)
#   description: 'External Secrets has been down or missing for 30 minutes on cluster {{ $labels.cluster_name }}.'
```

---

### File: `alerts/vm-workload/vmruntime-heartbeats-active-realtime.yaml`

**MQL Query:**
```mql
fetch k8s_container
| metric 'kubernetes.io/anthos/anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics'
| group_by 1m,
[value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean:
  mean(value.anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics)]
| every 1m
| group_by [resource.cluster_name],
[value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean_mean:
  mean(value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean)]
| absent_for 5m
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
absent(
  avg by (cluster_name) (
    kubernetes_io_anthos_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics
  )
)

# In Prometheus alert rule:
# alert: VMRuntimeMissingHeartbeat
# expr: absent(avg by (cluster_name) (kubernetes_io_anthos_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics))
# for: 5m
# labels:
#   severity: critical
# annotations:
#   summary: VMRuntime Missing Heartbeat (critical)
#   description: 'VMRuntime heartbeat metric has been missing for 5 minutes for cluster {{ $labels.cluster_name }}.'
```

---

### File: `alerts/vm-workload/vmruntime-heartbeats-realtime.yaml`

**MQL Query:**
```mql
fetch k8s_container
| metric 'kubernetes.io/anthos/anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics'
| group_by 1m,
[value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean:
  mean(value.anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics)]
| every 1m
| group_by [resource.cluster_name],
[value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean_mean:
  mean(value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean)]
| condition val() != 1
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
avg by (cluster_name) (
  kubernetes_io_anthos_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics
) != 1

# In Prometheus alert rule:
# alert: VMRuntimeHeartbeatDown
# expr: avg by (cluster_name) (kubernetes_io_anthos_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics) != 1
# for: 1m
# labels:
#   severity: critical
# annotations:
#   summary: VMRuntime Heartbeat down (critical)
#   description: 'VMRuntime heartbeat is not 1 (value: {{ $value }}) for cluster {{ $labels.cluster_name }}.'
```

---

### File: `alerts/vm-workload/vmruntime-vm-down-5m.yaml`

**MQL Query:**
```mql
fetch k8s_container
| metric 'kubernetes.io/anthos/kubevirt_info'
| filter (metadata.system_labels.state != 'ACTIVE')
| group_by 10m, [value_kubevirt_info_mean: mean(value.kubevirt_info)]
| every 10m
| condition val() > 0 '1'
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
sum(kubernetes_io_anthos_kubevirt_info{state!="ACTIVE"}) > 0

# In Prometheus alert rule:
# alert: VMInactive
# expr: sum(kubernetes_io_anthos_kubevirt_info{state!="ACTIVE"}) > 0
# for: 10m
# labels:
#   severity: critical
# annotations:
#   summary: VM inactive for greater than 10m (critical)
#   description: 'At least one VM has been in a non-ACTIVE state for more than 10 minutes. Count of inactive VMs: {{ $value }}.'
```

---

### File: `alerts/vm-workload/vmruntime-vm-missing-5m.yaml`

**MQL Query:**
```mql
fetch k8s_container
| metric 'kubernetes.io/anthos/kubevirt_vmi_vcpu_seconds'
| filter metric.kubernetes_vmi_label_kubevirt_vm =~ ".*"
| align rate(1m)
| every 1m
| group_by [metric.kubernetes_vmi_label_kubevirt_vm, resource.cluster_name],
  [value_kubevirt_vmi_vcpu_seconds_aggregate:
    aggregate(value.kubevirt_vmi_vcpu_seconds)]
| condition val() > 0 '1'
| absent_for 300s
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
(sum by (kubernetes_vmi_label_kubevirt_vm, cluster_name) (
  increase(kubernetes_io_anthos_kubevirt_vmi_vcpu_seconds_total{kubernetes_vmi_label_kubevirt_vm!=""}[5m])
) == 0)
AND ON (kubernetes_vmi_label_kubevirt_vm, cluster_name)
(kubernetes_io_anthos_kubevirt_info{state="ACTIVE", kubernetes_vmi_label_kubevirt_vm!=""} == 1)

# In Prometheus alert rule:
# alert: VMOfflineOrNoVCPUActivity
# expr: (sum by (kubernetes_vmi_label_kubevirt_vm, cluster_name) (increase(kubernetes_io_anthos_kubevirt_vmi_vcpu_seconds_total{kubernetes_vmi_label_kubevirt_vm!=""}[5m])) == 0) AND ON (kubernetes_vmi_label_kubevirt_vm, cluster_name) (kubernetes_io_anthos_kubevirt_info{state="ACTIVE", kubernetes_vmi_label_kubevirt_vm!=""} == 1)
# for: 1m
# labels:
#   severity: critical
#   vm_name: '{{ $labels.kubernetes_vmi_label_kubevirt_vm }}'
#   cluster_name: '{{ $labels.cluster_name }}'
# annotations:
#   summary: VM offline or no VCPU activity for greater than 5m (critical)
#   description: 'VM {{ $labels.kubernetes_vmi_label_kubevirt_vm }} in cluster {{ $labels.cluster_name }} is marked as ACTIVE but has shown no VCPU activity (increase over 5m is 0).'
```

---

### File: `alerts/vm-workload/vmruntime-vm-no-network-traffic-5m.yaml`

**MQL Query:**
```mql
fetch k8s_container
| metric 'kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total'
| align rate(3m)
| every 3m
| group_by [metric.kubernetes_vmi_label_kubevirt_vm],
    [value_kubevirt_vmi_network_transmit_bytes_total:
      aggregate(value.kubevirt_vmi_network_transmit_bytes_total)]
| condition value_kubevirt_vmi_network_transmit_bytes_total = cast_units(0, 'By/s')
| val(0)
```

**Proposed PromQL Translation:**
```promql
# Alert condition:
(sum by (kubernetes_vmi_label_kubevirt_vm) (
  rate(kubernetes_io_anthos_kubevirt_vmi_network_transmit_bytes_total[5m])
) == 0)
AND ON (kubernetes_vmi_label_kubevirt_vm)
(kubernetes_io_anthos_kubevirt_info{state="ACTIVE"} == 1)

# In Prometheus alert rule:
# alert: VMNoNetworkTraffic5m
# expr: (sum by (kubernetes_vmi_label_kubevirt_vm) (rate(kubernetes_io_anthos_kubevirt_vmi_network_transmit_bytes_total[5m])) == 0) AND ON (kubernetes_vmi_label_kubevirt_vm) (kubernetes_io_anthos_kubevirt_info{state="ACTIVE"} == 1)
# for: 1m
# labels:
#   severity: critical
#   vm_name: '{{ $labels.kubernetes_vmi_label_kubevirt_vm }}'
# annotations:
#   summary: VM has no network traffic for greater than 5m (critical)
#   description: 'VM {{ $labels.kubernetes_vmi_label_kubevirt_vm }} is ACTIVE but has shown no network transmit traffic (rate over 5m is 0 By/s).'
```

---
### Dashboards
---

### File: `dashboards/gdc-daily-report.json`

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
   **Proposed PromQL (for Grafana):**
   ```promql
   (
     sum by (node_name) (
       rate(kubernetes_io_anthos_node_cpu_core_usage_time{cluster_name=~"$market", cluster_name="$cluster_name"}[1m])
     )
     /
     avg by (node_name) (
       kubernetes_io_anthos_node_cpu_allocatable_cores{cluster_name=~"$market", cluster_name="$cluster_name"}
     )
   ) > 0
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
   **Proposed PromQL (for Grafana):**
   ```promql
   sum by (kubernetes_vmi_label_kubevirt_vm) (
     rate(kubernetes_io_anthos_kubevirt_vmi_network_transmit_bytes_total{cluster_name=~"$market", cluster_name="$cluster_name"}[2m])
   ) > 0
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
   **Proposed PromQL (for Grafana):**
   ```promql
   avg by (node_name) (
     kubernetes_io_anthos_node_cpu_allocatable_utilization{cluster_name=~"$market", cluster_name="$cluster_name"}
   ) * 100
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
   **Proposed PromQL (for Grafana):**
   ```promql
   avg by (node_name) (
     kubernetes_io_anthos_node_memory_allocatable_utilization{cluster_name=~"$market", cluster_name="$cluster_name"}
   ) * 100
   ```

**5. Widget: "Node Received Bytes"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/network/received_bytes_count'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | filter (metric.interface =~ 'enp81s0f.*')
   | align rate(1m)
   | every 1m
   | group_by [resource.node_name],
       [value_received_bytes_count_aggregate:
          aggregate(value.received_bytes_count)]
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   sum by (node_name) (
     rate(kubernetes_io_anthos_node_network_received_bytes_count_total{cluster_name=~"$market", cluster_name="$cluster_name", interface=~"enp81s0f.*"}[1m])
   )
   ```

**6. Widget: "Node Sent Bytes"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/network/sent_bytes_count'
   | ${cluster_name}
   | filter resource.cluster_name=~"${market.value}.*"
   | filter (metric.interface =~ 'enp81s0f.*')
   | align rate(1m)
   | every 1m
   | group_by [resource.node_name],
       [value_sent_bytes_count_aggregate:
          aggregate(value.sent_bytes_count)]
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   sum by (node_name) (
     rate(kubernetes_io_anthos_node_network_sent_bytes_count_total{cluster_name=~"$market", cluster_name="$cluster_name", interface=~"enp81s0f.*"}[1m])
   )
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
   | every 1m
   | scale '%'
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   avg by (pod_name) (
     kubernetes_io_anthos_container_cpu_request_utilization{cluster_name=~"$market", cluster_name="$cluster_name", pod_name=~"(virt-launcher).*", container_name="compute"}
   ) * 100
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
   **Proposed PromQL (for Grafana):**
   ```promql
   sum by (kubernetes_vmi_label_kubevirt_vm, interface) (
     rate(kubernetes_io_anthos_kubevirt_vmi_network_receive_bytes_total[1m])
   )
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
   **Proposed PromQL (for Grafana):**
   ```promql
   sum by (kubernetes_vmi_label_kubevirt_vm, interface) (
     rate(kubernetes_io_anthos_kubevirt_vmi_network_transmit_bytes_total[1m])
   )
   ```
---

### File: `dashboards/gdc-node-view.json`

**1. Widget: "Total Nodes" (Scorecard)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/cpu/total_cores'
   | ${project_id}
   | ${cluster_name}
   | group_by 10m, [value_total_cores_mean: mean(value.total_cores)]
   | every 10m
   | group_by [], [row_count: row_count()]
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   count(
     count by (node_name) (
       kubernetes_io_anthos_node_cpu_total_cores{project_id="$project_id", cluster_name="$cluster_name"}
     )
   )
   ```

**2. Widget: "Total Cores" (Scorecard)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/cpu/total_cores'
   | ${project_id}
   | ${cluster_name}
   | group_by 1m, [value_total_cores_mean: mean(value.total_cores)]
   | every 1m
   | group_by [],
       [value_total_cores_mean_aggregate: aggregate(value_total_cores_mean)]
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   sum(
     kubernetes_io_anthos_node_cpu_total_cores{project_id="$project_id", cluster_name="$cluster_name"}
   )
   ```
**3. Widget: "Allocatable Cores" (Scorecard)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/cpu/allocatable_cores'
   | ${project_id}
   | ${cluster_name}
   | group_by 1m, [value_allocatable_cores_mean: mean(value.allocatable_cores)]
   | every 1m
   | group_by [],
       [value_allocatable_cores_mean_aggregate:
          aggregate(value_allocatable_cores_mean)]
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   sum(
     kubernetes_io_anthos_node_cpu_allocatable_cores{project_id="$project_id", cluster_name="$cluster_name"}
   )
   ```

**4. Widget: "Total Memory" (Scorecard)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/memory/total_bytes'
   | ${project_id}
   | ${cluster_name}
   | group_by 1m, [value_total_bytes_mean: mean(value.total_bytes)]
   | every 1m
   | group_by [],
       [value_total_bytes_mean_aggregate: aggregate(value_total_bytes_mean)]
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   sum(
     kubernetes_io_anthos_node_memory_total_bytes{project_id="$project_id", cluster_name="$cluster_name"}
   )
   ```

**5. Widget: "Allocatable Memory" (Scorecard)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/memory/allocatable_bytes'
   | ${project_id}
   | ${cluster_name}
   | group_by 1m, [value_allocatable_bytes_mean: mean(value.allocatable_bytes)]
   | every 1m
   | group_by [],
       [value_allocatable_bytes_mean_aggregate:
          aggregate(value_allocatable_bytes_mean)]
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   sum(
     kubernetes_io_anthos_node_memory_allocatable_bytes{project_id="$project_id", cluster_name="$cluster_name"}
   )
   ```

**6. Widget: "CPU Usage per Node" (XYChart)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   { fetch k8s_node
     | metric 'kubernetes.io/anthos/node/cpu/allocatable_utilization'
   | ${project_id}
   | ${cluster_name}
     | group_by 1m,
         [value_allocatable_utilization_mean: mean(value.allocatable_utilization)]
     | every 1m
   ; fetch k8s_node
     | metric 'kubernetes.io/anthos/node/cpu/allocatable_cores'
   | ${project_id}
   | ${cluster_name}
     | group_by 1m, [value_allocatable_core_mean: mean(value.allocatable_cores)]
     | every 1m }
   | join
   | value [scaled_util: val(0) * val(1)]
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   (
     avg by (node_name) (
       kubernetes_io_anthos_node_cpu_allocatable_utilization{project_id="$project_id", cluster_name="$cluster_name"}
     )
     *
     avg by (node_name) (
       kubernetes_io_anthos_node_cpu_allocatable_cores{project_id="$project_id", cluster_name="$cluster_name"}
     )
   )
   ```

**7. Widget: "Memory Usage per Node" (XYChart)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
          fetch k8s_node
   | metric 'kubernetes.io/anthos/node/memory/used_bytes'
   | ${project_id}
   | ${cluster_name}
   | group_by 1m,
       [value_used_bytes_mean: mean(value.used_bytes)]
   | every 1m
   | group_by [resource.node_name],
       [value_used_bytes_mean_aggregate:
          aggregate(value_used_bytes_mean)]
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   sum by (node_name) ( # Assuming node_name is resource.node_name
     kubernetes_io_anthos_node_memory_used_bytes{project_id="$project_id", cluster_name="$cluster_name"}
   )
   ```

**8. Widget: "CPU Util % per Node" (XYChart)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/cpu/allocatable_utilization'
   | ${project_id}
   | ${cluster_name}
   | group_by 1m,    [value_allocatable_utilization_mean: mean(value.allocatable_utilization)]
   | every 1m
   | scale '%'
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   avg by (node_name) ( # Assuming default grouping by node
     kubernetes_io_anthos_node_cpu_allocatable_utilization{project_id="$project_id", cluster_name="$cluster_name"}
   ) * 100
   ```

**9. Widget: "Memory Util % per Node" (XYChart)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_node
   | metric 'kubernetes.io/anthos/node/memory/allocatable_utilization'
   | ${project_id}
   | ${cluster_name}
   | group_by 1m,
       [value_allocatable_utilization_mean: mean(value.allocatable_utilization)]
   | every 1m
   | group_by [resource.node_name],
       [value_allocatable_utilization_mean_aggregate:
          aggregate(value_allocatable_utilization_mean)]
   | scale '%'
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   avg by (node_name) (
     kubernetes_io_anthos_node_memory_allocatable_utilization{project_id="$project_id", cluster_name="$cluster_name"}
   ) * 100
   ```

**10. Widget: "Number of Containers per Node" (TimeSeriesTable)**
    **MQL Query (`timeSeriesQueryLanguage`):**
    ```mql
    fetch k8s_container
    | metric 'kubernetes.io/anthos/container/cpu/core_usage_time'
    | ${project_id}
    | ${cluster_name}
    | align rate(1m)
    | every 1m
    | group_by
        [resource.project_id, resource.location, resource.cluster_name,
         resource.namespace_name, resource.pod_name, resource.container_name,
         metadata.system.node_name],
        [value_core_usage_time_mean: pick_any(value.core_usage_time)]
    | group_by [metadata.system.node_name], [row_count()]
    ```
    **Proposed PromQL (for Grafana):**
    ```promql
    count by (node_name) (
      kube_pod_container_info{project_id="$project_id", cluster_name="$cluster_name"}
    )
    ```

**11. Widget: "Number of Pods per Node" (TimeSeriesTable)**
    **MQL Query (`timeSeriesQueryLanguage`):**
    ```mql
    fetch k8s_pod
    | metric 'kubernetes.io/anthos/pod/network/received_bytes_count'
    | ${project_id}
    | ${cluster_name}
    | align rate(1m)
    | every 1m
    | group_by [resource.project_id, resource.location, resource.cluster_name, resource.namespace_name, resource.pod_name, metadata.system.node_name],
        [value_received_bytes_count_mean: pick_any(value.received_bytes_count)]
        | group_by [metadata.system.node_name], [row_count()]
    ```
    **Proposed PromQL (for Grafana):**
    ```promql
    count by (node_name) (
      kube_pod_info{project_id="$project_id", cluster_name="$cluster_name"}
    )
    ```

**12. Widget: "Received bytes per node" (XYChart)**
    **MQL Query (`timeSeriesQueryLanguage`):**
    ```mql
    fetch k8s_node
    | metric 'kubernetes.io/anthos/node/network/received_bytes_count'
    | ${project_id}
    | ${cluster_name}
    | filter (metric.interface =~ 'enp81s0f.*')
    | align rate(1m)
    | every 1m
    | group_by [resource.node_name],
        [value_received_bytes_count_aggregate:
           aggregate(value.received_bytes_count)]
    ```
    **Proposed PromQL (for Grafana):**
    ```promql
    sum by (node_name) (
      rate(kubernetes_io_anthos_node_network_received_bytes_count_total{project_id="$project_id", cluster_name="$cluster_name", interface=~"enp81s0f.*"}[1m])
    )
    ```

**13. Widget: "Send bytes per node" (XYChart)**
    **MQL Query (`timeSeriesQueryLanguage`):**
    ```mql
    fetch k8s_node
    | metric 'kubernetes.io/anthos/node/network/sent_bytes_count'
    | ${project_id}
    | ${cluster_name}
    | filter (metric.interface =~ 'enp81s0f.*')
    | align rate(1m)
    | every 1m
    | group_by [resource.node_name],
        [value_sent_bytes_count_aggregate:
           aggregate(value.sent_bytes_count)]
    ```
    **Proposed PromQL (for Grafana):**
    ```promql
    sum by (node_name) (
      rate(kubernetes_io_anthos_node_network_sent_bytes_count_total{project_id="$project_id", cluster_name="$cluster_name", interface=~"enp81s0f.*"}[1m])
    )
    ```
**14. Widget: "Free Robin Disk Space % per Node" (XYChart)**
    **MQL Query (`timeSeriesQueryLanguage`):**
    ```mql
    {fetch k8s_container
    | metric 'external.googleapis.com/prometheus/robin_disk_nslices'
    | ${project_id}
    | ${cluster_name}
    | group_by [node_name],   [value_robin_disk_rawused_sum: mul(sum(value.robin_disk_nslices), 1073741824)]
    | every 1m
    ;
    fetch k8s_container
    | metric 'external.googleapis.com/prometheus/robin_disk_size'
    | ${project_id}
    | ${cluster_name}
    | group_by [node_name],   [value_robin_disk_size_mean: sum(value.robin_disk_size)]
    | every 1m
    }
    | join
    | value [v_0: 1 - div(t_0.value_robin_disk_rawused_sum, t_1.value_robin_disk_size_mean)]
    ```
    **Proposed PromQL (for Grafana):**
    ```promql
    (
      1 - (
        sum by (node_name) (robin_disk_nslices{project_id="$project_id", cluster_name="$cluster_name"}) * 1073741824
        /
        sum by (node_name) (robin_disk_size{project_id="$project_id", cluster_name="$cluster_name"})
      )
    ) * 100
    ```

**15. Widget: "Free Robin Disk Space % per Node" (TimeSeriesTable)**
    **MQL Query (`timeSeriesQueryLanguage`):**
    ```mql
    {fetch k8s_container
    | metric 'external.googleapis.com/prometheus/robin_disk_nslices'
    | ${project_id}
    | ${cluster_name}
    | group_by [Node: node_name],   [value_robin_disk_rawused_sum: mul(sum(value.robin_disk_nslices), 1073741824)]
    | every 1m
    ;
    fetch k8s_container
    | metric 'external.googleapis.com/prometheus/robin_disk_size'
    | ${project_id}
    | ${cluster_name}
    | group_by [Node: node_name],   [value_robin_disk_size_mean: mean(value.robin_disk_size)]
    | every 1m
    }
    | join
    | value [Disk_Free: cast_units(t_1.value_robin_disk_size_mean - t_0.value_robin_disk_rawused_sum, 'By')]
    ```
    **Proposed PromQL (for Grafana):**
    ```promql
    (
      sum by (node_name) (robin_disk_size{project_id="$project_id", cluster_name="$cluster_name"})
      -
      (sum by (node_name) (robin_disk_nslices{project_id="$project_id", cluster_name="$cluster_name"}) * 1073741824)
    )
    # Legend/column name in Grafana: {{node_name}}
    # Unit: Bytes
    ```

---

### File: `dashboards/gdc-robin-status.json`

This dashboard uses `timeSeriesFilter` which is MQL-like.

**1. Widget: "Robin Node State - ONLINE & READY"**
   **MQL-like Filter (`timeSeriesFilter.filter`):**
   ```
   metric.type="prometheus.googleapis.com/robin_node_state/gauge" resource.type="prometheus_target" metric.label."node_state"="ONLINE" metric.label."node_status"="Ready"
   ```
   **Aggregation:** `REDUCE_MEAN` grouped by `metric.label."node_name"`.
   **Proposed PromQL (for Grafana):**
   ```promql
   avg by (node_name) (
     robin_node_state_gauge{node_state="ONLINE", node_status="Ready"}
   )
   ```

**2. Widget: "Robin Disk State - ONLINE & READY"**
   **MQL-like Filter (`timeSeriesFilter.filter`):**
   ```
   metric.type="prometheus.googleapis.com/robin_disk_status/gauge" resource.type="prometheus_target" metric.label."disk_state"="READY" metric.label."disk_status"="ONLINE"
   ```
   **Aggregation:** `REDUCE_MEAN` grouped by `metric.label."node_name"`.
   **Proposed PromQL (for Grafana):**
   ```promql
   avg by (node_name) (
     robin_disk_status_gauge{disk_state="READY", disk_status="ONLINE"}
   )
   ```
**3. Widget: Node 1 - UNHEALTHY Services (TimeSeriesTable)**
   **MQL-like Filter (`timeSeriesFilter.filter`):**
   ```
   metric.type="prometheus.googleapis.com/robin_service_status/gauge" resource.type="prometheus_target" metric.label."node_name"="cnuc-1" metric.label."service_state"!="UP"
   ```
   **Aggregation:** `REDUCE_MEAN` grouped by `metric.label."service_state"`, `metric.label."service_name"`.
   **Proposed PromQL (for Grafana):**
   ```promql
   robin_service_status_gauge{node_name="cnuc-1", service_state!="UP"}
   ```
   (Similar for Node 2 and Node 3 with different `node_name` filters)

**4. Widget: prometheus/robin_service_status/gauge [COUNT] (XYChart)**
   **MQL-like Filter (`timeSeriesFilter.filter`):**
   ```
   metric.type="prometheus.googleapis.com/robin_service_status/gauge" resource.type="prometheus_target"
   ```
   **Aggregation:** `REDUCE_COUNT` grouped by `metric.label."service_state"`, `metric.label."service_name"`.
   **Proposed PromQL (for Grafana):**
   ```promql
   count by (service_state, service_name) (
     robin_service_status_gauge
   )
   ```
---

### File: `dashboards/gdc-vm-distribution.json`

**1. Widget: "Node 1" (VMs on Node 1)**
   **MQL Query (`timeSeriesQueryLanguage`):**
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
   **Proposed PromQL (for Grafana):**
   ```promql
   count by (created_by_name) (
     kube_pod_info{cluster_name="$cluster_name", pod=~"(virt-launcher).*", node=~".*01\\.ba\\.l\\.google\\.com"}
     AND ON (pod, namespace, cluster_name)
     kube_pod_status_phase{cluster_name="$cluster_name", pod=~"(virt-launcher).*", phase="Running"} == 1
   )
   ```
   (Similar queries for Node 2, Node 3, and Robin Master with different `metric.node` filters and `metric.pod` filters like `(robin-master).*`).

---

### File: `dashboards/gdc-vm-view.json`

**1. Widget: "VM States"**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric kubernetes.io/anthos/kubevirt_info
   | group_by [metadata.user.c'vm.kubevirt.io/name', metadata.system.state]
   | {ident; group_by sliding(24h)}
   | outer_join 0
   | value val(0)
   ```
   **Proposed PromQL (for Grafana):**
   ```promql
   sum by (vm_name, state) (
     kubernetes_io_anthos_kubevirt_info
   )
   ```

**2. Widget: "CPU usage per VM"**
   **MQL-like Filter (`timeSeriesFilter`):**
   Metric: `kubernetes.io/anthos/kubevirt_vmi_vcpu_seconds` (Counter)
   Aggregation: `ALIGN_RATE`, `REDUCE_MAX`
   GroupBy: `resource.label."cluster_name"`, `resource.label."location"`, `resource.label."node_name"`, `metric.label."kubernetes_vmi_label_kubevirt_vm"`
   AlignmentPeriod: `120s`
   **Proposed PromQL (for Grafana):**
   ```promql
   max by (cluster_name, location, node_name, kubernetes_vmi_label_kubevirt_vm) (
     rate(kubernetes_io_anthos_kubevirt_vmi_vcpu_seconds_total[2m])
   )
   ```

**3. Widget: "Network TX Bytes/s per VM per interface"**
   **MQL-like Filter (`timeSeriesFilter`):**
   Metric: `kubernetes.io/anthos/kubevirt_vmi_network_transmit_bytes_total` (Counter)
   Aggregation: `ALIGN_RATE`, `REDUCE_SUM`
   GroupBy: `resource.label."cluster_name"`, ..., `metric.label."kubernetes_vmi_label_kubevirt_vm"`, `metric.label."interface"`
   AlignmentPeriod: `120s`
   **Proposed PromQL (for Grafana):**
   ```promql
   sum by (cluster_name, location, node_name, kubernetes_vmi_label_kubevirt_vm, interface) (
     rate(kubernetes_io_anthos_kubevirt_vmi_network_transmit_bytes_total[2m])
   )
   ```
   (Similar structure for RX Bytes, TX/RX Errors, TX/RX Packets, TX/RX Packets Dropped, Storage Write/Read IOPS).

**4. Widget: "VMs" (TimeSeriesTable)**
   **MQL Query (`timeSeriesQueryLanguage`):**
   ```mql
   fetch k8s_container
   | metric 'kubernetes.io/anthos/kubevirt_info'
   | group_by [vm_name: metadata.user.c'kubevirt/vm', state: metadata.system_labels.state]
   ```
   **Proposed PromQL (for Grafana Table):**
   ```promql
   kubernetes_io_anthos_kubevirt_info
   # Table configured to show Time, vm_name, state, Value
   ```

---
This concludes the exhaustive list.
