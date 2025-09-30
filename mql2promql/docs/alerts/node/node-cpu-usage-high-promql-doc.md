# MQL to PromQL Conversion Guide - Node CPU Usage High

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/node/node-cpu-usage-high.yaml` alert.

## `alerts/node/node-cpu-usage-high.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Node allocatable cpu cores percent | MQL | `fetch prometheus_target \| metric 'kubernetes.io/anthos/kube_node_status_allocatable/gauge' \| ...` | (Reasoning to be added) | PromQL | (PromQL query to be added) | (Comments to be added) |
