resource "google_monitoring_alert_policy" "node-cpu-usage-high-alert" {
  display_name = "Node cpu usage exceeds 80 percent (critical)"
  combiner = "OR"
  conditions {
    display_name = "Node allocatable cpu cores percent"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          { t_0:
              fetch k8s_container
              | metric 'kubernetes.io/anthos/kube_node_status_allocatable'
              | filter (metric.resource == 'cpu')
              | group_by 1m,
                  [value_kube_node_status_allocatable_mean:
                     mean(value.kube_node_status_allocatable)]
              | every 1m
              | group_by
                  [resource.cluster_name, metric.node, resource.location,
                   resource.project_id],
                  [value_kube_node_status_allocatable_mean_aggregate:
                     aggregate(value_kube_node_status_allocatable_mean)]
          ; t_1:
              fetch k8s_container
              | metric 'kubernetes.io/anthos/kube_node_status_capacity'
              | filter (metric.resource == 'cpu')
              | group_by 1m,
                  [value_kube_node_status_capacity_mean:
                     mean(value.kube_node_status_capacity)]
              | every 1m
              | group_by
                  [metric.node, resource.cluster_name, resource.project_id,
                   resource.location],
                  [value_kube_node_status_capacity_mean_aggregate:
                     aggregate(value_kube_node_status_capacity_mean)] }
          | join
          | value
              [v_0:
                 div(t_0.value_kube_node_status_allocatable_mean_aggregate,
                   t_1.value_kube_node_status_capacity_mean_aggregate)]
      ; t_2:
          fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
          | filter (metric.anthos_distribution = 'baremetal')
          | align mean_aligner()
          | group_by [resource.project_id, resource.location, resource.cluster_name],
              [value_anthos_cluster_info_aggregate:
                 aggregate(value.anthos_cluster_info)]
          | every 1m }
      | join
      | window 1m
      | value [t_0.v_0]
      | condition t_0.v_0 < 0.2 '1'
        EOL
      
      duration = "600s"
      trigger {
        count = 1
      }
    }
  }
}
      