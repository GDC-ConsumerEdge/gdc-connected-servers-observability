# MQL to PromQL Conversion Guide

This document lists Monitoring Query Language (MQL) queries found in the [Alerts](../alerts/) and [Dashboards](../dashboards/) repositories and provides status on the translations to Prometheus Query Language (PromQL).

## Summary of Files Containing MQL Queries

| File Path                                                  | Contains MQL? | Notes                                                                 | Conversion Status |
| :--------------------------------------------------------- | :------------ | :-------------------------------------------------------------------- | :---------------- |
| `dashboards/gdc-daily-report.json`                         | Yes (Partial) | Mixed MQL (`timeSeriesQueryLanguage`) and PromQL (`prometheusQuery`). | To be verified               |
| `dashboards/gdc-external-secrets.json`                     | No            | Uses `prometheusQuery`.                                               | N/A               |
| `dashboards/gdc-logs.json`                                 | No            | Log panel filters, not metric queries.                                | N/A               |
| `dashboards/gdc-node-view.json`                            | Yes           | Uses `timeSeriesQueryLanguage`.                                       | WIP               |
| `dashboards/gdc-robin-status.json`                         | Yes (Partial) | Mixed MQL (`timeSeriesFilter` with MQL-like filter) and PromQL.     | WIP               |
| `dashboards/gdc-vm-distribution.json`                      | Yes           | Uses `timeSeriesQueryLanguage`.                                       | To be verified    |
| `dashboards/gdc-vm-view.json`                              | Yes (Partial) | Mixed MQL (`timeSeriesQueryLanguage`, `timeSeriesFilter`) and PromQL. | To be verified    |
| `alerts/control-plane/api-server-error-ratio-5-percent.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              | To be verified               |
| `alerts/control-plane/apiserver-down.yaml`                 | Yes           | `conditionMonitoringQueryLanguage` used.                              | To be verified    |
| `alerts/control-plane/controller-manager-down.yaml`        | Yes           | `conditionMonitoringQueryLanguage` used.                              | To be verified    |
| `alerts/control-plane/scheduler-down.yaml`                 | Yes           | `conditionMonitoringQueryLanguage` used.                              | To be verified    |
| `alerts/node/multiple-nodes-not-ready-realtime.yaml`       | Yes           | `conditionMonitoringQueryLanguage` used.                              | WIP               |
| `alerts/node/node-cpu-usage-high.yaml`                     | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/node/node-memory-usage-high.yaml`                  | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/node/node-not-ready-30m.yaml`                      | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/pods/pod-crash-looping.yaml`                       | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/pods/pod-not-ready-1h.yaml`                        | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/storage/robin-disk-inactive-10m.yaml`              | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/storage/robin-master-down-10m.yaml`                | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/storage/robin-node-offline-30m.json`               | Yes           | JSON format, uses `conditionThreshold` with MQL-like filter.        | TBD               |
| `alerts/system/configsync-down-30m.yaml`                   | Yes           | `conditionAbsent` with MQL-like filter.                             | TBD               |
| `alerts/system/configsync-high-apply-duration-1h.yaml`     | No            | Uses `conditionPrometheusQueryLanguage`.                              | N/A               |
| `alerts/system/configsync-old-last-sync-2h.yaml`           | No            | Uses `conditionPrometheusQueryLanguage`.                              | N/A               |
| `alerts/system/coredns-down.yaml`                          | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/system/coredns-servfail-ratio-1-percent.yaml`      | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/system/externalsecrets-down-30m.yaml`              | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/system/externalsecrets-sync-error.yaml`            | No            | Uses `conditionPrometheusQueryLanguage`.                              | N/A               |
| `alerts/vm-workload/vmruntime-heartbeats-active-realtime.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-heartbeats-realtime.yaml`    | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-vm-down-5m.yaml`             | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-vm-missing-5m.yaml`          | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |
| `alerts/vm-workload/vmruntime-vm-no-network-traffic-5m.yaml` | Yes           | `conditionMonitoringQueryLanguage` used.                              | TBD               |

### Glossary of Conversion Status

- **N/A**: Not Applicable. The file does not contain any MQL queries that require conversion.
- **TBD**: To Be Done. The file contains MQL queries, but the conversion has not been started yet.
- **WIP**: Work In Progress. The conversion for this file is currently in progress.
- **To be verified**: The conversion has been completed, but it is pending review and verification.
- **Completed**: The conversion has been completed and verified.

---

## Deployment of Converted Dashboards and Alerts

To deploy the converted dashboards and alerts, you can use the provided shell scripts.

### Dashboards

To deploy the PromQL only [dashboards](./dashboards-promql/), run the following command from the `mql2promql/dashboards-promql` directory:

```bash
./create-dashboards-promql.sh
```

### Alerts

To deploy the PromQL only [alerts](./alerts-promql/), run the following command from the `mql2promql/alerts-promql` directory:

```bash
./create-alerts-promql.sh
```
