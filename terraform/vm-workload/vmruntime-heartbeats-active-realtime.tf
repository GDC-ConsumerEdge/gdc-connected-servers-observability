resource "google_monitoring_alert_policy" "vmruntime-heartbeats-missing-alert" {
  display_name = "VMRuntime Missing Heartbeat (critical)"
  combiner = "OR"
  conditions {
    display_name = "VMRuntime Heartbeat is up"
    condition_monitoring_query_language {
      query = <<EOL
      fetch k8s_container
      | metric 'kubernetes.io/anthos/anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics'
      | group_by 1m,
      [value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean:
        mean(value.anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics)]
      | every 1m
      | group_by [resource.cluster_name],
      [value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean_mean:
        mean(value_anthos_baremetal_cluster_heartbeat_for_kubevirt_metrics_mean)] 
      | absent_for 5m
        EOL
      
      duration = "0s"
      trigger {
        count = 1
      }
    }
  }
}