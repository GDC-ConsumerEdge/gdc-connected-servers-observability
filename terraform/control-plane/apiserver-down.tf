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

resource "google_monitoring_alert_policy" "apiserver-down-alert" {
  display_name = "API server down (critical)"
  combiner = "OR"
  conditions {
    display_name = "API server is up"
    condition_monitoring_query_language {
      query = <<EOL
        { t_0:
          fetch k8s_container
          | metric 'kubernetes.io/anthos/container/uptime'
          | filter (resource.container_name =~ 'kube-apiserver')
          | align mean_aligner()
          | group_by 1m, [value_up_mean: mean(value.uptime)]
          | every 1m
          | group_by [resource.project_id, resource.location, resource.cluster_name],
              [value_up_mean_aggregate: aggregate(value_up_mean)]
        ; t_1:
            fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
            | filter (metric.anthos_distribution = 'baremetal')
            | align mean_aligner()
            | group_by [resource.project_id, resource.location, resource.cluster_name],
                [value_anthos_cluster_info_aggregate:
                  aggregate(value.anthos_cluster_info)]
            | every 1m }
        | join
        | value [t_0.value_up_mean_aggregate]
        | window 1m
        | absent_for 300s
        EOL
      
      duration = "0s"
      trigger {
        count = 1
      }
    }
  }
}