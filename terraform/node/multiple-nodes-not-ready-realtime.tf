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

resource "google_monitoring_alert_policy" "multiple-nodes-not-ready-alert" {
  display_name = "Multiple nodes not ready (critical)"
  combiner = "OR"
  conditions {
    display_name = "Multiple nodes not ready"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          fetch prometheus_target
          | metric 'kubernetes.io/anthos/kube_node_status_condition/gauge'
          | filter (metric.condition == 'Ready' && metric.status != 'true')
          | group_by [resource.project_id, resource.location, resource.cluster],
              [value_kube_node_status_condition_mean:
                 mean(value.gauge)]
          | every 1m
      ; t_1:
          fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
          | filter (metric.anthos_distribution = 'baremetal')
          | align mean_aligner()
          | group_by [resource.project_id, resource.location, cluster: resource.cluster_name],
              [value_anthos_cluster_info_aggregate:
                 aggregate(value.anthos_cluster_info)]
          | every 1m }
      | join
      | value [t_0.value_kube_node_status_condition_mean]
      | window 1m
      | condition t_0.value_kube_node_status_condition_mean > 0 '1'
        EOL
      
      duration = "60s"
      trigger {
        count = 2
      }
    }
  }
}