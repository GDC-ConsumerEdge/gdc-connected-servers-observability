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

resource "google_monitoring_alert_policy" "node-memory-usage-high-alert" {
  display_name = "Node memory usage exceeds 80 percent (critical)"
  combiner = "OR"
  conditions {
    display_name = "Node allocatable memory percent"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          fetch prometheus_target
          | metric 'kubernetes.io/anthos/node_memory_MemAvailable_bytes/gauge'
          | group_by [resource.cluster, resource.instance, resource.location,
               resource.project_id],
              [value_node_memory_MemAvailable_bytes_mean:
                 mean(value.gauge)]
          | every 1m
      ; t_1:
          fetch prometheus_target
          | metric 'kubernetes.io/anthos/node_memory_MemTotal_bytes/gauge'
          | group_by [resource.instance, resource.cluster, resource.project_id,
               resource.location],
              [value_node_memory_MemTotal_bytes_mean:
                 mean(value.gauge)]
          | every 1m
      }
      | join
      | value
          [v_0:
             div(t_0.value_node_memory_MemAvailable_bytes_mean,
               t_1.value_node_memory_MemTotal_bytes_mean)]
      | window 1m
      | condition v_0 < 0.2 '1'
        EOL
      
      duration = "600s"
      trigger {
        count = 1
      }
    }
  }
}