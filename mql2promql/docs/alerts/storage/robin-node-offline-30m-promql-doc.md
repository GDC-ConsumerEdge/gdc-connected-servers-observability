# MQL to PromQL Conversion Guide - Robin Node Offline 30m

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/storage/robin-node-offline-30m.json` alert.

## `alerts/storage/robin-node-offline-30m.json`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Robin node is offline for more than 30 minutes | MQL | `fetch gce_instance \| metric 'custom.googleapis.com/robin/health/status' \| ...` | (Reasoning to be added) | PromQL | (PromQL query to be added) | (Comments to be added) |
