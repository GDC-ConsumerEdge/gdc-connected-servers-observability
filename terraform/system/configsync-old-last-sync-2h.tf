resource "google_monitoring_alert_policy" "configsync-old-last-sync-alert" {
  display_name = "Config Sync Old Last Sync Timestamp"
  combiner = "OR"
  conditions {
    display_name = "Config Sync Old Last Sync Timestamp"
    condition_prometheus_query_language {
      query = <<EOL
      time() - topk by (cluster, configsync_sync_kind, configsync_sync_name, configsync_sync_namespace) (1, custom_googleapis_com:opencensus_config_sync_last_sync_timestamp{monitored_resource="generic_node",status="success"}) > 7200
        EOL
      
      duration = "0s"
    }
  }
}