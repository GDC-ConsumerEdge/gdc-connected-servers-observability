Here is a summarized, self-contained write-up for the `MQL_TO_PROMQL_CONVERSION_GUIDE.md` file. It details the conversion process for the "GDC - VM status" dashboard, explains the rationale behind the final queries, and clarifies the known differences.

---

### `dashboards/gdc-vm-view.json`

This section details the conversion of the "GDC - VM status" dashboard, which is composed of various widgets monitoring individual virtual machine metrics like CPU, network, and storage. The original dashboard primarily used MQL `timeSeriesFilter` queries and `timeSeriesQueryLanguage` for more complex aggregations.

The conversion process involved several key challenges, including incorrect metric name translations, issues with dashboard rendering of grouped time series, and incorrect label selectors (`resource_type` vs. `monitored_resource`). The final PromQL queries address these issues, resulting in a functional dashboard.

| Group | Input Query Title | Input Query Type | Source Query (MQL) | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| N/A | VM States | `timeSeriesQueryLanguage` | `fetch k8s_container \| metric kubernetes.io/anthos/kubevirt_info \| group_by [metadata.user.c'vm.kubevirt.io/name', metadata.system.state]` | A direct PromQL equivalent failed to render correctly in the dashboard. The final query was changed to count only "Running" VMs as a pragmatic workaround to provide a stable chart. | `prometheusQuery` | `sum by (created_by_name) (kubernetes_io:anthos_kube_pod_info_gauge{...} AND on(pod) kubernetes_io:anthos_kube_pod_status_phase_gauge{...})` | This represents a functional change from showing all states to only showing active VMs. |
| N/A | CPU usage per VM | `timeSeriesFilter` | `metric.type="kubernetes.io/anthos/kubevirt_vmi_vcpu_seconds", crossSeriesReducer: "REDUCE_MAX", perSeriesAligner: "ALIGN_RATE"` | The MQL filter is translated to PromQL by converting the metric name, mapping `REDUCE_MAX` to `max by (...)`, and `ALIGN_RATE` to `rate(...)`. The label selector was corrected from `resource_type` to `monitored_resource`. | `prometheusQuery` | `max by (cluster_name, location, node_name, kubernetes_vmi_label_kubevirt_vm) (rate(kubernetes_io:anthos_kubevirt_vmi_vcpu_seconds{monitored_resource="k8s_container"}[2m]))` | |
| N/A | Network TX Bytes/s per VM per interface | `timeSeriesFilter` | `metric.type="...network_transmit_bytes_total", crossSeriesReducer: "REDUCE_SUM", perSeriesAligner: "ALIGN_RATE"` | The MQL filter is translated to PromQL by converting the metric name, mapping `REDUCE_SUM` to `sum by (...)`, and `ALIGN_RATE` to `rate(...)`. | `prometheusQuery` | `sum by (..., interface) (rate(kubernetes_io:anthos_kubevirt_vmi_network_transmit_bytes_total{monitored_resource="k8s_container"}[2m]))` | This pattern applies to all network and storage widgets. |
| N/A | VMs | `timeSeriesQueryLanguage` | `... group_by [vm_name: ..., state: ...]` | The MQL query creates aliases for labels. The PromQL equivalent uses the raw metric and relies on `columnSettings` in the dashboard JSON to map the correct labels (`kubernetes_vmi_label_kubevirt_vm`, `state`) to the table columns. | `prometheusQuery` | `kubernetes_io:anthos_kubevirt_info` | |

#### Reasoning for Conversion Choices

1.  **Metric Naming and Filtering**: A primary issue causing "No data" was the incorrect translation of MQL filters.
    *   **Metric Name**: MQL metric names like `kubernetes.io/anthos/kubevirt_vmi_vcpu_seconds` were correctly converted to PromQL format, becoming `kubernetes_io:anthos_kubevirt_vmi_vcpu_seconds`.
    *   **Resource Label**: The MQL filter `resource.type="k8s_container"` was initially translated to `{resource_type="k8s_container"}`. The correct label for Google Cloud's Managed Service for Prometheus is `monitored_resource`, so the selector was changed to `{monitored_resource="k8s_container"}` to resolve the "No data" issue.

2.  **Aggregation and Alignment**: MQL `timeSeriesFilter` aggregations were mapped to PromQL functions.
    *   `"perSeriesAligner": "ALIGN_RATE"` was consistently translated to the `rate(...[2m])` function in PromQL.
    *   `"crossSeriesReducer": "REDUCE_MAX"` was translated to `max by (...)`, and `"crossSeriesReducer": "REDUCE_SUM"` was translated to `sum by (...)`, with the `groupByFields` from MQL becoming the labels in the `by` clause.

3.  **Handling Dashboard Rendering Issues (for "VM States")**: The original "VM States" chart was designed to show a line for each VM, indicating its current state (e.g., "Running", "Terminated"). A direct PromQL equivalent, `count by (kubernetes_vmi_label_kubevirt_vm, state) (kubernetes_io:anthos_kubevirt_info)`, failed to render correctly in the dashboard, instead showing a single aggregated line. After several attempts to work around this rendering issue, a pragmatic decision was made to change the chart's function to display only *active* VMs. The final query joins `kube_pod_info` (which contains the VM name) with `kube_pod_status_phase` to filter for running pods, providing a stable and functional, albeit different, visualization.

#### Final Conclusion

The converted PromQL dashboard is now stable and correctly displays data for most widgets, matching the original MQL dashboard's resource utilization charts. The critical "No data" issues have been resolved by correcting metric names and resource label selectors. The only significant gap is a functional trade-off in the "VM States" widget, which now serves as a reliable view of "Running VMs" rather than a complete state lifecycle chart, due to persistent dashboard rendering issues with multi-label grouping queries.
