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

resource "google_monitoring_alert_policy" "robin-storage-free-space" {
  display_name = "Robin Storage Free Space < ${var.free_space_threshold_percent}%"
  combiner     = "OR"
  severity     = "CRITICAL"

  conditions {
    display_name = "Robin Storage Free Space < ${var.free_space_threshold_percent}%"

    condition_prometheus_query_language {
      query = <<-EOL
        (
          100 *
          (
            1 -
              (
                sum by (cluster_name, node_name) (
                  {__name__="external.googleapis.com/prometheus/robin_disk_nslices",
                  monitored_resource="k8s_container"}
                ) * 1073741824
                /
                sum by (cluster_name, node_name) (
                  {__name__="external.googleapis.com/prometheus/robin_disk_size",
                  monitored_resource="k8s_container"}
                )
              )
          )
        ) <= ${var.free_space_threshold_percent}
      EOL

      duration            = var.duration
      evaluation_interval = var.evaluation_interval
    }
  }

  documentation {
    content   = <<-EOT
      CRITICAL: Robin Storage Near Exhaustion
      The Robin storage pool has less than ${var.free_space_threshold_percent}% free space remaining.

      Impact:
      Applications will soon be unable to write data, leading to crashes and data corruption.

      Action Required:
      1. Immediate: Identify and delete unnecessary snapshots or orphaned PVCs.
      2. Cleanup: Check for log accumulation in /var/log or application-specific paths.
      3. Expansion: Plan for adding physical storage capacity to the GDC node.
    EOT
    mime_type = "text/markdown"
    subject   = "Robin Disk < ${var.free_space_threshold_percent}% | Node: $${metric.label.node_name} | Cluster: $${metric.label.cluster_name}"
  }
}