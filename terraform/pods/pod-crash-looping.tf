resource "google_monitoring_alert_policy" "pod-crash-looping-alert" {
  display_name = "Pod crash looping (critical)"
  combiner = "OR"
  conditions {
    display_name = "Pod restart times [15m]"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          fetch k8s_container
          | metric 'kubernetes.io/anthos/kube_pod_container_status_restarts_total'
          | filter (metric.pod !~ '^(bm-system|robin-prejob).*')
          | align delta(15m)
          | every 15m
          | group_by
              [resource.project_id, resource.location, resource.cluster_name,
               metric.namespace, metric.container],
              [value_kube_pod_container_status_restarts_total_aggregate:
                 aggregate(value.kube_pod_container_status_restarts_total)]
      ; t_1:
          fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
          | filter (metric.anthos_distribution = 'baremetal')
          | align mean_aligner()
          | group_by [resource.project_id, resource.location, resource.cluster_name],
              [value_anthos_cluster_info_aggregate:
                 aggregate(value.anthos_cluster_info)]
          | every 15m }
      | join
      | value [t_0.value_kube_pod_container_status_restarts_total_aggregate]
      | window 15m
      | condition t_0.value_kube_pod_container_status_restarts_total_aggregate > 0 '1'
        EOL
      
      duration = "900s"
      trigger {
        count = 1
      }
    }
  }
}
