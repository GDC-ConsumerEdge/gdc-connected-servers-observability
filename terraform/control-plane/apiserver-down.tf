resource "google_monitoring_alert_policy" "apiserver-down-alert" {
  display_name = "API server down (critical)"
  combiner = "OR"
  conditions {
    display_name = "API server is up"
    condition_monitoring_query_language {
      query = <<EOL
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
        EOL
      
      duration = "0s"
      trigger {
        count = 1
      }
    }
  }
}