# MQL to PromQL Conversion Guide - Node Not Ready 30m

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/node/node-not-ready-30m.yaml` alert.

## `alerts/node/node-not-ready-30m.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Node not ready for more than 30 minutes | MQL | `fetch prometheus_target \| metric 'kubernetes.io/anthos/kube_node_status_condition/gauge' \| ...` | (Reasoning to be added) | PromQL | (PromQL query to be added) | (Comments to be added) |
