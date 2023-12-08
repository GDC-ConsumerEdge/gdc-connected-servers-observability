resource "google_monitoring_alert_policy" "vmruntime-vm-down-alert" {
  display_name = "VM inactive for greater than 5m (critical)"
  combiner = "OR"
  conditions {
    display_name = "VM is active"
    condition_monitoring_query_language {
      query = <<EOL
      fetch k8s_container
      | metric 'kubernetes.io/anthos/kubevirt_info'
      | filter (metadata.system_labels.state != 'ACTIVE')
      | group_by 10m, [value_kubevirt_info_mean: mean(value.kubevirt_info)]
      | every 10m
      | condition val() > 0 '1'
        EOL
      
      duration = "0s"
      trigger {
        percent = 50
      }
    }
  }
}