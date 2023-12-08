resource "google_monitoring_alert_policy" "node-memory-usage-high-alert" {
  display_name = "Node memory usage exceeds 80 percent (critical)"
  combiner = "OR"
  conditions {
    display_name = "Node allocatable memory percent"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          fetch k8s_node
          | metric 'kubernetes.io/anthos/node_memory_MemAvailable_bytes'
          | group_by 1m,
              [value_node_memory_MemAvailable_bytes_mean:
                 mean(value.node_memory_MemAvailable_bytes)]
          | every 1m
          | group_by
              [resource.cluster_name, resource.node_name, resource.location,
               resource.project_id],
              [value_node_memory_MemAvailable_bytes_mean_aggregate:
                 aggregate(value_node_memory_MemAvailable_bytes_mean)]
      ; t_1:
          fetch k8s_node
          | metric 'kubernetes.io/anthos/node_memory_MemTotal_bytes'
          | group_by 1m,
              [value_node_memory_MemTotal_bytes_mean:
                 mean(value.node_memory_MemTotal_bytes)]
          | every 1m
          | group_by
              [resource.node_name, resource.cluster_name, resource.project_id,
               resource.location],
              [value_node_memory_MemTotal_bytes_mean_aggregate:
                 aggregate(value_node_memory_MemTotal_bytes_mean)] }
      | join
      | value
          [v_0:
             div(t_0.value_node_memory_MemAvailable_bytes_mean_aggregate,
               t_1.value_node_memory_MemTotal_bytes_mean_aggregate)]
      | condition v_0 < 0.2 '1'
        EOL
      
      duration = "600s"
      trigger {
        count = 1
      }
    }
  }
}