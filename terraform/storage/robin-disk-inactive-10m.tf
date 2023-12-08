resource "google_monitoring_alert_policy" "robin-disk-inactive-alert" {
  display_name = "Robin disk no status for more than 10 minutes (critical)"
  combiner = "OR"
  conditions {
    display_name = "Robin disk no status more than 10 minutes"
    condition_monitoring_query_language {
      query = <<EOL
      fetch prometheus_target
      | metric 'prometheus.googleapis.com/robin_disk_status/gauge'
      | group_by 1m, [value_robin_disk_status_mean: mean(value.robin_disk_status)]
      | every 1m
      | group_by [metric.disk_wwn, metric.disk_state],
          [value_robin_disk_status_mean_mean: mean(value_robin_disk_status_mean)]
      | condition val() < 1 '1'
        EOL
      
      duration = "300s"
      trigger {
        percent = 50
      }
    }
  }
}