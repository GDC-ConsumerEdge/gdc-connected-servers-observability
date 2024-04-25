resource "google_logging_metric" "kube_fledged_log_metric" {
  name   = "kube-fledged-sync"
  filter = "resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"kube-fledged\" AND resource.labels.container_name=\"controller\" AND jsonPayload.log=~\"Completed sync actions for image cache [\\w-]+\\(statusupdate\\)\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "kube_fledged_alert_policy" {
  display_name = "kube-fledged sync log missing"
  documentation {
    content = "## Missing kube-fledged sync logs\n\n### Summary\n\nThe sync log of any healthy cluster in the project is missing in 1.5 sync cycles. The default sync cycle is 15 minutes."
    mime_type = "text/markdown"
    subject = "Alert: Missing kube-fledged sync logs"
  }
  combiner     = "OR"
  conditions {
    display_name = "kube-fledged sync logs missing"
    condition_prometheus_query_language {
      # - By default the kube-fledged sync interval is 15min, thus aggregation window is 
      # set to 1.5 * sync interval, which is 22min in the PromQL query, to gurantee that 
      # there is at least 1 sync log captured per cluster. Adjust accordingly.
      # - Please notified that the log-based-metric will stop once the log is missing.
      # Here we use cluster health-check as "pad", to enforce the metric per cluster.
      # PromQL cannot increase the cardinality of the vector, thus we need the vector with
      # complete list of clusters on the leftmost side
      query      = "((sum by (cluster_name) (kubernetes_io:anthos_computed_cluster_health{monitored_resource=\"k8s_container\",healthcheck_type=\"kubernetes\"} * 0)) + on(cluster_name) group_left() (sum by (cluster_name) (increase(logging_googleapis_com:user_kube_fledged_sync{monitored_resource=\"k8s_container\"}[22m]))) or (sum by (cluster_name) (kubernetes_io:anthos_computed_cluster_health{monitored_resource=\"k8s_container\",healthcheck_type=\"kubernetes\"} * 0))) < 0.5"
      duration   = "300s"  # There could some "noises" on the log-based-metrics
      evaluation_interval = "60s"
    }
  }
  alert_strategy {
    auto_close  = "604800s"  # 7 days
  }
  severity = "WARNING"
  
  depends_on = [resource.google_logging_metric.kube_fledged_log_metric]
}
