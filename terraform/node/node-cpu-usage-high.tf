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

resource "google_monitoring_alert_policy" "node-cpu-usage-high-alert" {
  display_name = "Node cpu usage exceeds 80 percent (critical)"
  combiner = "OR"
  conditions {
    display_name = "Node allocatable cpu cores percent"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          { t_0:
              fetch prometheus_target
              | metric 'kubernetes.io/anthos/kube_node_status_allocatable/gauge'
              | filter (metric.resource == 'cpu')
              | group_by [metric.node, resource.cluster, resource.location, resource.project_id],
                  [value_kube_node_status_allocatable_mean:
                     mean(value.gauge)]
              | every 1m
          ; t_1:
              fetch prometheus_target
              | metric 'kubernetes.io/anthos/kube_node_status_capacity/gauge'
              | filter (metric.resource == 'cpu')
              | group_by [metric.node, resource.cluster, resource.location, resource.project_id],
                  [value_kube_node_status_capacity_mean:
                     mean(value.gauge)]
              | every 1m }
          | join
          | value
              [v_0:
                 div(t_0.value_kube_node_status_allocatable_mean,
                   t_1.value_kube_node_status_capacity_mean)]
      ; t_2:
          fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
          | filter (metric.anthos_distribution = 'baremetal')
          | align mean_aligner()
          | group_by [resource.project_id, resource.location, cluster: resource.cluster_name],
              [value_anthos_cluster_info_aggregate:
                 aggregate(value.anthos_cluster_info)]
          | every 1m }
      | join
      | window 1m
      | value [t_0.v_0]
      | condition t_0.v_0 < 0.2 '1'
        EOL
      
      duration = "600s"
      trigger {
        count = 1
      }
    }
  }
}
      