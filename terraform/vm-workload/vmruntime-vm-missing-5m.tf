# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "google_monitoring_alert_policy" "vmruntime-vm-missing-alert" {
  display_name = "VM offline for greater than 5m (critical)"
  combiner = "OR"
  conditions {
    display_name = "VM is offline"
    condition_monitoring_query_language {
      query = <<EOL
      fetch k8s_container
      | metric 'kubernetes.io/anthos/kubevirt_vmi_vcpu_seconds'
      | filter metric.kubernetes_vmi_label_kubevirt_vm =~ ".*"
      | align rate(1m)
      | every 1m
      | group_by [metric.kubernetes_vmi_label_kubevirt_vm, resource.cluster_name],
        [value_kubevirt_vmi_vcpu_seconds_aggregate:
          aggregate(value.kubevirt_vmi_vcpu_seconds)]
      | condition val() > 0 '1'
      | absent_for 300s
        EOL
      
      duration = "0s"
      trigger {
        count = 1
      }
    }
  }
}