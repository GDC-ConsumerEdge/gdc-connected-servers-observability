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

resource "google_monitoring_alert_policy" "coredns-down-alert" {
  display_name = "CoreDNS down (critical)"
  combiner     = "OR"

  # This label allows the alert to show up in your "Managed" UI filter
  user_labels = {
    managed = "true"
  }

  conditions {
    display_name = "CoreDNS is up"
    condition_prometheus_query_language {
      query    = "(max by (cluster, location, project_id) (label_replace(kubernetes_io:anthos_anthos_cluster_info{anthos_distribution=\"baremetal\", monitored_resource=\"k8s_container\"}, \"cluster\", \"$1\", \"cluster_name\", \"(.*)\"))) unless (avg by (cluster, location, project_id) (kubernetes_io:anthos_container_uptime{container_name=~\"coredns\", monitored_resource=\"k8s_container\"}))"
      duration = "300s"
      trigger {
        count = 1
      }
    }
  }
}
