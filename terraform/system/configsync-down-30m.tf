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

resource "google_monitoring_alert_policy" "configsync-down-alert" {
  display_name = "ConfigSync down for 30 minutes (critical)"
  combiner = "OR"
  conditions {
    display_name = "ConfigSync is up"
    condition_absent {
      filter = "resource.type = \"generic_node\" AND metric.type = \"custom.googleapis.com/opencensus/config_sync/resource_count\""
      duration = "1800s"
      trigger {
        percent = 100
      }

      aggregations {
        alignment_period = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
}