resource "google_monitoring_alert_policy" "node-not-ready-alert" {
  display_name = "Node not ready for more than 30 minutes (critical)"
  combiner = "OR"
  conditions {
    display_name = "Node not ready for more than 30 minutes"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          fetch prometheus_target
          | metric 'kubernetes.io/anthos/kube_node_status_condition/gauge'
          | filter (metric.condition != 'Ready' && metric.status == 'true')
          | group_by 1m,
              [value_kube_node_status_condition_mean:
                 mean(value.gauge)]
          | every 1m
          | group_by [resource.project_id, resource.location, resource.cluster],
              [value_kube_node_status_condition_mean_aggregate:
                 aggregate(value_kube_node_status_condition_mean)]
      ; t_1:
          fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
          | filter (metric.anthos_distribution = 'baremetal')
          | align mean_aligner()
          | group_by [resource.project_id, resource.location, resource.cluster_name],
              [value_anthos_cluster_info_aggregate:
                 aggregate(value.anthos_cluster_info)]
          | every 1m }
      | join
      | value [t_0.value_kube_node_status_condition_mean_aggregate]
      | window 1m
      | condition t_0.value_kube_node_status_condition_mean_aggregate > 0 '1'
        EOL
      
      duration = "1800s"
      trigger {
        count = 1
      }
    }
  }
}