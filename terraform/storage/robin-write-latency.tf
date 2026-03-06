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

resource "google_monitoring_alert_policy" "robin-write-latency" {
  display_name = "Robin Write Latency > ${var.write_latency_threshold_display} for ${var.duration_display}"
  combiner     = "OR"
  severity     = "WARNING"

  conditions {
    display_name = "Robin Write Latency > ${var.write_latency_threshold_display} for ${var.duration_display}"

    condition_prometheus_query_language {
      query = <<-EOL
        (
          avg by (cluster_name) (
            increase({__name__="external.googleapis.com/prometheus/robin_rio_vol_total_write_usecs",
                      monitored_resource="k8s_container"}[${var.rate_window}])
            /
            increase({__name__="external.googleapis.com/prometheus/robin_rio_vol_total_write_ios",
                      monitored_resource="k8s_container"}[${var.rate_window}])
          )
          > ${var.write_latency_threshold_usecs}
        )
      EOL

      duration            = var.duration
      evaluation_interval = var.evaluation_interval
    }
  }

  documentation {
    content   = <<-EOT
      Warning: High Robin Write Storage Latency
      Storage I/O write latency has exceeded ${var.write_latency_threshold_display} for over ${var.duration_display}.

      Possible Causes:
      - Disk Bottleneck: High I/O wait times on the underlying physical drives.
      - Heavy Workload: A specific pod or service is performing intensive disk operations.
      - Storage Fabric Issues: Potential congestion in the Robin.io storage layer or networking bandwidth.

      Action Required:
      1. Identify the affected cluster: $${resource.labels.cluster_name}
      2. Check the Robin.io dashboard to pinpoint the specific volume or disk.
      3. Review node disk health via the GDC console.
    EOT
    mime_type = "text/markdown"
    subject   = "Robin Write Latency > ${var.write_latency_threshold_display} for ${var.duration_display} | Cluster: $${metric.label.cluster_name}"
  }
}