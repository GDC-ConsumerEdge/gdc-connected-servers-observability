resource "google_monitoring_alert_policy" "robin-node-offline-alert" {
  display_name = "robin-node-not-online-30m"
  combiner = "OR"
  conditions {
    display_name = "Prometheus Target - prometheus/robin_node_state/gauge"
    condition_threshold {
      filter = "resource.type = \"prometheus_target\" AND metric.type = \"prometheus.googleapis.com/robin_node_state/gauge\""
      comparison = "COMPARISON_LT"
      duration = "0s"
      threshold_value = 1
      trigger {
        percent = 50
      }

      aggregations {
        alignment_period = "1800s"
        cross_series_reducer = "REDUCE_MEAN"
        per_series_aligner = "ALIGN_MEAN"
        group_by_fields = [
          "metric.label.service_name",
          "metric.label.node_name"
        ]
      }
    }
  }
}