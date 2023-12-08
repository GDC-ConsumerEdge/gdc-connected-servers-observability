resource "google_monitoring_alert_policy" "configsync-high-apply-duration-alert" {
  display_name = "Config Sync High Apply Duration"
  combiner = "OR"
  conditions {
    display_name = "Config Sync High Apply Duration"
    condition_prometheus_query_language {
      query = <<EOL
      histogram_quantile(0.9, sum by (cluster, configsync_sync_kind,configsync_sync_name, configsync_sync_namespace, le) (rate(custom_googleapis_com:opencensus_config_sync_apply_duration_seconds_bucket{monitored_resource="generic_node"}[5h]))) > 3600
        EOL
      
      duration = "300s"
    }
  }
}