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

resource "google_monitoring_alert_policy" "node-cpu-utilization-high" {
  display_name = "Node vCPU Utilization Exceeds ${var.vcpu_utilization_threshold_percent}% for ${var.duration_display}"
  combiner     = "OR"
  severity     = "WARNING"

  conditions {
    display_name = "Node vCPU Utilization Exceeds ${var.vcpu_utilization_threshold_percent}% for ${var.duration_display}"

    condition_prometheus_query_language {
      query = <<-EOL
        (
          100 *
          sum by (location, cluster_name, node_name) (
            rate(kubernetes_io:anthos_node_cpu_core_usage_time{monitored_resource="k8s_node"}[${var.rate_window}])
          )
          /
          sum by (location, cluster_name, node_name) (
            kubernetes_io:anthos_node_cpu_total_cores{monitored_resource="k8s_node"}
          )
        ) > ${var.vcpu_utilization_threshold_percent}
      EOL

      duration            = var.duration
      evaluation_interval = var.evaluation_interval
    }
  }

  documentation {
    content   = <<-EOT
      Warning: High vCPU Utilization Detected.
      The vCPU usage has remained above ${var.vcpu_utilization_threshold_percent}% for ${var.duration_display}.
    EOT
    mime_type = "text/markdown"
    subject   = "vCPU Utilization exceeds ${var.vcpu_utilization_threshold_percent}% for ${var.duration_display} | Node: $${metric.label.node_name} | Cluster: $${metric.label.cluster_name}"
  }
}