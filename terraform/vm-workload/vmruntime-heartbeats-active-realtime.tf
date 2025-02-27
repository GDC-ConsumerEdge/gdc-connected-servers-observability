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