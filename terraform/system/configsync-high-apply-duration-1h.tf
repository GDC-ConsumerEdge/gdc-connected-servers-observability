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

resource "google_monitoring_alert_policy" "configsync-high-apply-duration-alert" {
  display_name = "Config Sync High Apply Duration"
  combiner = "OR"
  conditions {
    display_name = "Config Sync High Apply Duration"
    condition_prometheus_query_language {
      query = <<EOL
      histogram_quantile(0.9, sum by (cluster, configsync_sync_kind,configsync_sync_name, configsync_sync_namespace, le) (rate(custom_googleapis_com:opencensus_config_sync_apply_duration_seconds_bucket{monitored_resource="generic_node"}[5h]))) > 3600
        EOL
      
      duration = "300s"
    }
  }
}