resource "google_monitoring_alert_policy" "robin-master-down-alert" {
  display_name = "Robin master not online for more than 10 minutes (critical)"
  combiner = "OR"
  conditions {
    display_name = "Robin master not online more than 10 minutes"
    condition_monitoring_query_language {
      query = <<EOL
      fetch prometheus_target
      | metric 'prometheus.googleapis.com/robin_node_state/gauge'
      | filter (metric.node_role == 'MANAGER_MASTER')
      | group_by 10m,
         [value_robin_node_state_aggregate: aggregate(value.robin_node_state)]
      | every 10m
      | group_by [], [row_count: row_count()]
      | condition val() < 1 '1'
        EOL
      
      duration = "0s"
      trigger {
        percent = 50
      }
    }
  }
}
