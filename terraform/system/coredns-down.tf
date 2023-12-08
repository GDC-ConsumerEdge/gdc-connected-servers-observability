resource "google_monitoring_alert_policy" "coredns-down-alert" {
  display_name = "CoreDNS down (critical)"
  combiner = "OR"
  conditions {
    display_name = "CoreDNS is up"
    condition_monitoring_query_language {
      query = <<EOL
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
      | condition val() < 1
        EOL
      
      duration = "0s"
      trigger {
        count = 1
      }
    }
  }
}