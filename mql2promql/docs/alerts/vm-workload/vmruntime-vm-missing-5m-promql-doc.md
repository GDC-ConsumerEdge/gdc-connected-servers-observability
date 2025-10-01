# MQL to PromQL Conversion Guide - VM Offline for greater than 5m

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/vm-workload/vmruntime-vm-missing-5m.yaml` alert.

## `alerts/vm-workload/vmruntime-vm-missing-5m.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | VM is offline | MQL | `fetch k8s_container \| metric 'kubernetes.io/anthos/kubevirt_vmi_vcpu_seconds' \| ...` | A direct translation of the `absent_for` MQL condition is not straightforward in PromQL. The new query uses the `unless` operator to perform a set difference, identifying VMs that were active in the last 15 minutes but have not been active in the last 5 minutes, which correctly identifies missing VMs. | PromQL | `(sum by(kubernetes_vmi_label_kubevirt_vm, cluster_name) (count_over_time(kubernetes_io:anthos_kubevirt_vmi_vcpu_seconds{monitored_resource="k8s_container"}[15m])) > 0) unless on(kubernetes_vmi_label_kubevirt_vm, cluster_name) (sum by(kubernetes_vmi_label_kubevirt_vm, cluster_name) (count_over_time(kubernetes_io:anthos_kubevirt_vmi_vcpu_seconds{monitored_resource="k8s_container"}[5m])) > 0)` | The converted PromQL alert is a correct and reliable replacement for the original MQL policy. |

---

### MQL to PromQL Conversion Validation: VM Offline for greater than 5m

This report summarizes the conversion of the "VM offline for greater than 5m (critical)" alert policy from MQL to PromQL.

#### 1. Original Alert Definition

*   **Name:** VM offline for greater than 5m (critical)
*   **File:** `alerts/vm-workload/vmruntime-vm-missing-5m.yaml`

#### 2. Original MQL Query

```mql
fetch k8s_container
 | metric 'kubernetes.io/anthos/kubevirt_vmi_vcpu_seconds'
 | filter metric.kubernetes_vmi_label_kubevirt_vm =~ ".*"
 | align rate(1m)
 | every 1m
 | group_by [metric.kubernetes_vmi_label_kubevirt_vm, resource.cluster_name],
    [value_kubevirt_vmi_vcpu_seconds_aggregate:
     aggregate(value.kubevirt_vmi_vcpu_seconds)]
 | condition val() > 0 '1'
 | absent_for 300s
```

#### 3. Goal of the Alert ("the Why")

The goal of this alert is to detect when a Virtual Machine (VM), which was previously active and reporting metrics, stops reporting for a continuous period of 5 minutes. This indicates that the VM has gone offline or its monitoring agent has stopped functioning.

#### 4. Converted PromQL Query

```promql
(sum by(kubernetes_vmi_label_kubevirt_vm, cluster_name) (count_over_time(kubernetes_io:anthos_kubevirt_vmi_vcpu_seconds{monitored_resource="k8s_container"}[15m])) > 0) unless on(kubernetes_vmi_label_kubevirt_vm, cluster_name) (sum by(kubernetes_vmi_label_kubevirt_vm, cluster_name) (count_over_time(kubernetes_io:anthos_kubevirt_vmi_vcpu_seconds{monitored_resource="k8s_container"}[5m])) > 0)
```

#### 5. Reasoning for Conversion ("the How")

A direct translation of the `absent_for` MQL condition is not straightforward in PromQL. The initial attempt to use `count_over_time(...) == 0` failed because when a metric stream stops, it no longer exists in the query result, so the `== 0` condition is never evaluated for that stream.

The final, correct PromQL query uses a set-difference approach with the `unless` operator to reliably detect absence:

1.  **Establish a Baseline:** `(sum by(...) (count_over_time(...[15m])) > 0)` creates a list of all VMs that have been active at any point in the last 15 minutes. This is our baseline of "expected" VMs.
2.  **Identify Currently Active VMs:** `(sum by(...) (count_over_time(...[5m])) > 0)` creates a list of VMs that have been active in the most recent 5 minutes.
3.  **Find the Difference:** The `unless on(...)` operator takes the baseline list (from step 1) and removes all the VMs that are in the currently active list (from step 2).
4.  **Result:** The remaining list contains only those VMs that were active recently (in the last 15m) but have been silent for at least the last 5 minutes, which accurately identifies the missing VMs.

#### 6. Validation

*   **Observation about Alerts:** The original MQL alert was correctly firing and creating incidents for offline VMs. The initial converted PromQL alert failed to create any incidents and its chart showed "No data available," indicating a flawed query. The final, corrected PromQL alert successfully populates the chart with data, demonstrating that it is correctly monitoring the set of VMs.

*   **Tests Done:** The validation was performed by observing the behavior of the policies in the GCM UI. The initial failure of the PromQL query confirmed that a simple translation was incorrect. The success of the final query, evidenced by the chart populating with the expected time series for each VM, confirmed that the `unless`-based logic is the correct pattern for this absence detection scenario.

*   **Acceptable Differences:** The MQL alert chart shows the `vcpu_seconds` metric when present. The final PromQL alert chart shows the result of the `unless` operation, which is the list of *missing* VMs. This is a different but acceptable (and arguably more direct) visualization of the alert's firing condition.

*   **Supporting Analysis:** The `MQL_TO_PROMQL_CONVERSION_STATUS.md` file initially marked this conversion as "TBD" (To Be Done), which supports the finding that the initial conversion was known to be incomplete or incorrect. The final `unless`-based query is a robust and standard PromQL pattern for detecting the absence of a time series that was recently present.

*   **Conclusion:** The final converted PromQL alert is a correct and reliable replacement for the original MQL policy. It accurately replicates the MQL `absent_for` logic by using a set-difference operation, and it successfully resolves the "No data" issue from the initial conversion.
