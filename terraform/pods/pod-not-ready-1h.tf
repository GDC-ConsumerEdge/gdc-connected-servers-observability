resource "google_monitoring_alert_policy" "pod-not-ready-alert" {
  display_name = "Pod not ready for more than one hour (critical)"
  combiner = "OR"
  conditions {
    display_name = "Pod not ready for more than one hour"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          fetch k8s_container
          | metric 'kubernetes.io/anthos/kube_pod_status_phase'
          | filter (metric.phase =~ 'Pending|Unknown|Failed')
          | filter (resource.pod_name !~ '^(bm-system||robin-prejob).*')
          | group_by 1m,
              [value_kube_pod_status_phase_mean: mean(value.kube_pod_status_phase)]
          | every 1m
          | group_by
              [resource.project_id, resource.location, resource.cluster_name,
               metric.namespace, metric.pod],
              [value_kube_pod_status_phase_mean_aggregate:
                 aggregate(value_kube_pod_status_phase_mean)]
      ; t_1:
          fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
          | filter (metric.anthos_distribution = 'baremetal')
          | align mean_aligner()
          | group_by [resource.project_id, resource.location, resource.cluster_name],
              [value_anthos_cluster_info_aggregate:
                 aggregate(value.anthos_cluster_info)]
          | every 1m }
      | join
      | value [t_0.value_kube_pod_status_phase_mean_aggregate]
      | window 1m
      | condition t_0.value_kube_pod_status_phase_mean_aggregate > 0 '1'
        EOL
      
      duration = "3600s"
      trigger {
        count = 1
      }
    }
  }
}