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

resource "google_monitoring_alert_policy" "robin-node-offline-alert" {
  display_name = "robin-node-not-online-30m"
  combiner = "OR"
  conditions {
    display_name = "Prometheus Target - prometheus/robin_node_state/gauge"
    condition_threshold {
      filter = "resource.type = \"prometheus_target\" AND metric.type = \"prometheus.googleapis.com/robin_node_state/gauge\""
      comparison = "COMPARISON_LT"
      duration = "0s"
      threshold_value = 1
      trigger {
        percent = 50
      }

      aggregations {
        alignment_period = "1800s"
        cross_series_reducer = "REDUCE_MEAN"
        per_series_aligner = "ALIGN_MEAN"
        group_by_fields = [
          "metric.label.service_name",
          "metric.label.node_name"
        ]
      }
    }
  }
}