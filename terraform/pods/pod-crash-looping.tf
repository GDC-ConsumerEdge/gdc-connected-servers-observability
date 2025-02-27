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

resource "google_monitoring_alert_policy" "pod-crash-looping-alert" {
  display_name = "Pod crash looping (critical)"
  combiner = "OR"
  conditions {
    display_name = "Pod restart times [15m]"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          fetch prometheus_target
          | metric 'kubernetes.io/anthos/kube_pod_container_status_restarts_total/counter'
          | filter (metric.pod !~ '^(bm-system|robin-prejob).*')
          | align delta(15m)
          | every 15m
          | group_by
              [resource.project_id, resource.location, resource.cluster,
               resource.namespace, metric.container],
              [value_kube_pod_container_status_restarts_total_aggregate:
                 aggregate(value.counter)]
      ; t_1:
          fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
          | filter (metric.anthos_distribution = 'baremetal')
          | align mean_aligner()
          | group_by [resource.project_id, resource.location, cluster: resource.cluster_name],
              [value_anthos_cluster_info_aggregate:
                 aggregate(value.anthos_cluster_info)]
          | every 15m }
      | join
      | value [t_0.value_kube_pod_container_status_restarts_total_aggregate]
      | window 15m
      | condition t_0.value_kube_pod_container_status_restarts_total_aggregate > 0 '1'
        EOL
      
      duration = "900s"
      trigger {
        count = 1
      }
    }
  }
}
