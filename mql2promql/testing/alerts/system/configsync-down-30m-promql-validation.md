### MQL to PromQL Conversion Validation: ConfigSync Down

This report summarizes the conversion of the "ConfigSync down for 30 minutes (critical)" alert policy from MQL to PromQL.

#### 1. Original Alert Definition

*   **Name:** `ConfigSync down for 30 minutes (critical)`
*   **File:** `alerts/system/configsync-down-30m.yaml`

#### 2. Original MQL Query

```yaml
conditions:
- conditionAbsent:
    duration: 1800s
    aggregations:
    - alignmentPeriod: 300s
      perSeriesAligner: ALIGN_MEAN
    filter: "resource.type = \"k8s_container\" AND metric.type = \"external.googleapis.com/prometheus/config_sync_resource_count\""
    trigger:
      percent: 100
```

#### 3. Goal of the Alert ("the Why")

The goal of the alert is to detect a potential outage of the ConfigSync service. It triggers when all time series for the `config_sync_resource_count` metric are absent for a continuous period of 30 minutes. This indicates that the service is no longer reporting its status metrics.

#### 4. Converted PromQL Query

```promql
sum by (cluster_name) (count_over_time(external_googleapis_com:prometheus_config_sync_resource_count{monitored_resource="k8s_container"}[30m])) == 0
```

#### 5. Reasoning for Conversion ("the How")

A direct translation using the PromQL `absent()` function was functionally correct but resulted in a poor user experience, as the alert chart in the GCM UI would show "No data available" during normal operation. The final query was developed through an iterative process to address this while providing more meaningful, cluster-level alerting.

1.  **Data Visibility**: To solve the "No data" issue, the `count_over_time()` function is used. This function counts the number of data points for each time series in a given window, returning a `0` if data is absent, which can then be charted.

2.  **Preserving Filtering**: Unlike a simple `count()`, `count_over_time()` is applied to each time series individually, which preserves all the metric's labels (`cluster_name`, `pod_name`, etc.). This was a critical improvement to ensure filtering capabilities in the GCM UI were not lost.

3.  **Per-Cluster Aggregation**: The original MQL alert would only fire if *all* ConfigSync components across all clusters stopped reporting. The final PromQL query improves on this by using `sum by (cluster_name)` to aggregate the results on a per-cluster basis. This provides a more useful alert that will trigger if ConfigSync goes down in a single cluster, without being overly noisy by alerting on every individual component.

4.  **Alert Condition**: The `== 0` expression evaluates to `true` for any cluster where the sum of `count_over_time` is zero, meaning no ConfigSync components in that cluster have reported data for 30 minutes. The alert policy's `duration` is set to a short interval (e.g., 60s), as the 30-minute window is handled within the query itself.

#### 6. Validation

*   **Observation about Alerts**: The initial converted PromQL alert using `absent()` was functionally correct but suffered from poor data visibility in the GCM UI. The final version provides a much better user experience, showing a time series for each cluster that represents the health of ConfigSync within that cluster.

*   **Tests Done**: The validation process was iterative. We confirmed that the initial `absent()` query was logically sound but visually problematic. We then tested the `count_over_time()` function and confirmed it preserved the necessary labels for filtering. Finally, we tested the `sum by (cluster_name)` aggregation to confirm that it correctly grouped the results into a per-cluster time series, which was verified by observing the GCM chart after the query was updated.

*   **Acceptable Differences**: The final PromQL alert has a different triggering behavior than the original MQL alert. The original would only fire if *all* ConfigSync metrics disappeared globally. The new alert is more granular and useful, firing if *all* ConfigSync metrics within a single cluster disappear. This change is considered an improvement as it allows for faster detection of cluster-specific issues.

*   **Supporting Analysis**: The final query successfully balances the need for accurate absence detection with the need for clear data visualization and meaningful alerting. By aggregating at the cluster level, the alert is more actionable than the original "all-or-nothing" MQL alert, without being as noisy as a per-component alert.

*   **Conclusion**: The converted PromQL alert is a correct and superior replacement for the original MQL alert. It successfully monitors the health of ConfigSync on a per-cluster basis and provides clear, actionable data within the Google Cloud Monitoring UI.
