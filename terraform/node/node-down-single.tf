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

resource "google_monitoring_alert_policy" "node-down-single" {
  display_name = "1 GDC Node Down for more than ${var.duration_display}"
  combiner     = "OR"
  severity     = "CRITICAL"

  conditions {
    display_name = "1 Node Missing for more than ${var.duration_display}"

    condition_prometheus_query_language {
      query = <<-EOL
        (
          sum by (cluster_name, node_name) (
            last_over_time(kubernetes_io:anthos_node_cpu_core_usage_time{monitored_resource="k8s_node"}[${var.lookback_window}])
            unless
            kubernetes_io:anthos_node_cpu_core_usage_time{monitored_resource="k8s_node"}
          )
        )
        and on (cluster_name)
        (
          count by (cluster_name) (
            last_over_time(kubernetes_io:anthos_node_cpu_core_usage_time{monitored_resource="k8s_node"}[${var.lookback_window}])
            unless
            kubernetes_io:anthos_node_cpu_core_usage_time{monitored_resource="k8s_node"}
          ) == 1
        )
      EOL

      duration            = var.duration
      evaluation_interval = var.evaluation_interval
    }
  }

  documentation {
    content   = <<-EOT
      Critical: 1 Node Missing
      1 node has lost contact to Google Cloud Platform for more than ${var.duration_display}.

      Possible Causes:
      * Node Failure: The node is physically down or powered off.
      * Network Partition: The node cannot reach Google Cloud.
      * Survivability Mode: If other nodes follow, the site may be entering disconnected mode.
    EOT
    mime_type = "text/markdown"
    subject   = "1 GDC Node Down for more than ${var.duration_display} | Cluster: $${resource.label.cluster_name} | Node: $${resource.label.node_name}"
  }
}