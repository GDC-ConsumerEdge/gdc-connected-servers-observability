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

resource "google_monitoring_alert_policy" "nodes-down-multiple" {
  display_name = "GDC Nodes Down (${var.node_count_threshold}+ nodes for ${var.duration_display} or more)"
  combiner     = "OR"
  severity     = "WARNING"

  conditions {
    display_name = "${var.node_count_threshold}+ Nodes Missing for ${var.duration_display} or more"

    condition_prometheus_query_language {
      query = <<-EOL
        count by (cluster_name) (
          max_over_time(kubernetes_io:anthos_node_cpu_core_usage_time{monitored_resource="k8s_node"}[${var.lookback_window}])
          unless
          kubernetes_io:anthos_node_cpu_core_usage_time{monitored_resource="k8s_node"}
        ) >= ${var.node_count_threshold}
      EOL

      duration            = var.duration
      evaluation_interval = var.evaluation_interval
    }
  }

  documentation {
    content   = <<-EOT
      Critical: Multiple Nodes Missing (Potential Disconnect)
      ${var.node_count_threshold} or more Nodes have lost contact with Google Cloud Platform for more than ${var.duration_display}.

      Possible Causes:
      1. Survivability Mode: The entire cluster may have lost connection to Google Cloud. Workloads may still be running locally.
      2. Major Outage: Multiple physical nodes have failed.

      Action Required:
      * Attempt to reach the cluster via local/out-of-band management.
      * Verify if the site is in Survivability Mode or if this is a hard outage.
    EOT
    mime_type = "text/markdown"
    subject   = "${var.node_count_threshold}+ Nodes Missing for ${var.duration_display} or more | Cluster: $${resource.label.cluster_name}"
  }
}