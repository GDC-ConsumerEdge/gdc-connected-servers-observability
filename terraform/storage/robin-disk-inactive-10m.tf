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

resource "google_monitoring_alert_policy" "robin-disk-inactive-alert" {
  display_name = "Robin disk no status for more than 10 minutes (critical)"
  combiner = "OR"
  conditions {
    display_name = "Robin disk no status more than 10 minutes"
    condition_monitoring_query_language {
      query = <<EOL
      fetch prometheus_target
      | metric 'prometheus.googleapis.com/robin_disk_status/gauge'
      | group_by 1m, [value_robin_disk_status_mean: mean(value.robin_disk_status)]
      | every 1m
      | group_by [metric.disk_wwn, metric.disk_state],
          [value_robin_disk_status_mean_mean: mean(value_robin_disk_status_mean)]
      | condition val() < 1 '1'
        EOL
      
      duration = "300s"
      trigger {
        percent = 50
      }
    }
  }
}