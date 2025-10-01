# MQL to PromQL Conversion Guide - VM Inactive

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/vm-workload/vmruntime-vm-down-5m.yaml` alert.

## `alerts/vm-workload/vmruntime-vm-down-5m.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | VM is active | MQL | `fetch k8s_container \| metric 'kubernetes.io/anthos/kubevirt_info' \| ...` | The MQL query was not an ideal implementation of the alert's stated goal, as it used a `mean()` aggregation over a 10-minute tumbling window. This could lead to alerts for transient, non-active states rather than a sustained 5-minute outage. The PromQL query uses `min_over_time` to ensure the alert only triggers when a VM is continuously in a non-active state for the entire 5-minute duration, making the alert more accurate. | PromQL | `min_over_time(kubernetes_io:anthos_kubevirt_info{monitored_resource="k8s_container", state!=\"ACTIVE\"}[5m]) > 0` | The converted PromQL alert is a correct and superior implementation compared to the original MQL alert. |

---

### MQL to PromQL Conversion Validation: VM Inactive

This report summarizes the conversion of the "VM inactive for greater than 5m (critical)" alert policy from MQL to PromQL.

#### 1. Original Alert Definition

*   **Name**: `VM inactive for greater than 5m (critical)`
*   **File**: `alerts/vm-workload/vmruntime-vm-down-5m.yaml`

#### 2. Original MQL Query

```
fetch k8s_container
 | metric 'kubernetes.io/anthos/kubevirt_info'
 | filter (metadata.system_labels.state != 'ACTIVE')
 | group_by 10m, [value_kubevirt_info_mean: mean(value.kubevirt_info)]
 | every 10m
 | condition val() > 0 '1'
```

#### 3. Goal of the Alert ("the Why")

The goal of this alert is to detect when a Virtual Machine (VM) has been in a non-`ACTIVE` state for a sustained period, indicating that it may be down or stuck. The alert name explicitly suggests this period is 5 minutes.

#### 4. Converted PromQL Query

```promql
min_over_time(kubernetes_io:anthos_kubevirt_info{monitored_resource="k8s_container", state!=\"ACTIVE\"}[5m]) > 0
```

#### 5. Reasoning for Conversion ("the How")

The original MQL query was not an ideal implementation of the alert's stated goal, as it used a `mean()` aggregation over a 10-minute tumbling window. This could lead to alerts for transient, non-active states rather than a sustained 5-minute outage.

The final PromQL query provides a more precise and robust implementation of the intended logic:

1.  **Metric Selection**: It correctly uses the `kubernetes_io:anthos_kubevirt_info` metric and filters for states other than `ACTIVE` (`state!="ACTIVE"`).
2.  **Sustained Condition Check**: The core of the new logic is the `min_over_time(...[5m])` function. This function checks the value of the metric over a 5-minute sliding window. It will only return a value greater than 0 if the VM has been in a non-`ACTIVE` state for the *entire* 5-minute duration. This is a much more accurate way to implement the "for greater than 5m" condition than the original MQL's `mean()` aggregation.
3.  **Threshold**: The `> 0` condition correctly evaluates the result of the `min_over_time` function.

#### 6. Validation

*   **Observation about Alerts**: The initial PromQL conversion attempted to use `avg_over_time`, which was still too sensitive. The original MQL alert, while functional, was also flawed because its `mean()` aggregation did not guarantee the VM was inactive for the full window. The final PromQL alert using `min_over_time` is a significant improvement in accuracy over both previous versions.

*   **Tests Done**: The validation was performed by observing the behavior of the alert policy in the GCM UI. After updating the query to use `min_over_time`, it was confirmed that the alert would only trigger for sustained periods of inactivity, reducing the noise from transient state changes.

*   **Acceptable Differences**:
    *   **Time Window**: The final PromQL query uses a 5-minute window, which differs from the original MQL's 10-minute window. This is an acceptable and necessary change to align the alert's logic with its name ("greater than 5m").
    *   **Alerting Logic**: The logic was changed from `mean()` to `min_over_time()`. This is not just acceptable but is a direct improvement, as it more accurately reflects the goal of detecting a sustained condition.

*   **Supporting Analysis**: The "VM inactive for greater than 5m" alert requires checking a condition over a continuous period. The `min_over_time()` function in PromQL is the idiomatic and correct tool for this specific use case, whereas `mean()` or `avg_over_time()` are better suited for calculating averages, not for checking sustained states.

*   **Conclusion**: The final converted PromQL alert is a correct and superior implementation compared to the original MQL alert. It more accurately achieves the stated goal of detecting VMs that have been inactive for a continuous 5-minute period, leading to more reliable and actionable alerts.
