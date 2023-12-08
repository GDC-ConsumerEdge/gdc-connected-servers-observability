resource "google_monitoring_alert_policy" "coredns-servfail-ratio-1-percent-alert" {
  display_name = "CoreDNS SERVFAIL count ratio exceeds 1 percent"
  combiner = "OR"
  conditions {
    display_name = "CoreDNS SERVFAIL count ratio: SERVFAIL counts / all response counts"
    condition_monitoring_query_language {
      query = <<EOL
      { t_0:
          { t_0:
              fetch k8s_container
              | metric 'kubernetes.io/anthos/coredns_dns_responses_total'
              | filter (metric.rcode == 'SERVFAIL')
              | align delta(5m)
              | every 5m
              | group_by
                  [resource.project_id, resource.location, resource.cluster_name],
                  [value_coredns_dns_responses_total_aggregate:
                     aggregate(value.coredns_dns_responses_total)]
          ; t_1:
              fetch k8s_container
              | metric 'kubernetes.io/anthos/coredns_dns_responses_total'
              | align delta(5m)
              | every 5m
              | group_by
                  [resource.project_id, resource.location, resource.cluster_name],
                  [value_coredns_dns_responses_total_aggregate:
                     aggregate(value.coredns_dns_responses_total)] }
          | join
          | value
              [v_0:
                 div(t_0.value_coredns_dns_responses_total_aggregate,
                   t_1.value_coredns_dns_responses_total_aggregate)]
      ; t_2:
          fetch k8s_container::kubernetes.io/anthos/anthos_cluster_info
          | filter (metric.anthos_distribution = 'baremetal')
          | align mean_aligner()
          | group_by [resource.project_id, resource.location, resource.cluster_name],
              [value_anthos_cluster_info_aggregate:
                 aggregate(value.anthos_cluster_info)]
          | every 5m }
      | join
      | value [t_0.v_0]
      | window 5m
      | condition t_0.v_0 > 0.01 '1'
        EOL
      
      duration = "600s"
      trigger {
        count = 1
      }
    }
  }
}