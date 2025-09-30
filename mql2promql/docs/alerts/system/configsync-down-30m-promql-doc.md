# MQL to PromQL Conversion Guide - Config Sync Down 30m

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/system/configsync-down-30m.yaml` alert.

## `alerts/system/configsync-down-30m.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Config Sync is down for more than 30 minutes | MQL | `fetch prometheus_target \| metric 'prometheus.googleapis.com/config_sync_status/gauge' \| ...` | (Reasoning to be added) | PromQL | (PromQL query to be added) | (Comments to be added) |
