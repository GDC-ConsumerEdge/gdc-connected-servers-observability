resource "google_monitoring_alert_policy" "configsync-down-alert" {
  display_name = "ConfigSync down for 30 minutes (critical)"
  combiner = "OR"
  conditions {
    display_name = "ConfigSync is up"
    condition_absent {
      filter = "resource.type = \"generic_node\" AND metric.type = \"custom.googleapis.com/opencensus/config_sync/resource_count\""
      duration = "1800s"
      trigger {
        percent = 100
      }

      aggregations {
        alignment_period = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
}