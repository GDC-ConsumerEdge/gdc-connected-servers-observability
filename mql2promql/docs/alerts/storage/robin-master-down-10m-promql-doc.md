# MQL to PromQL Conversion Guide - Robin Master Down 10m

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/storage/robin-master-down-10m.yaml` alert.

## `alerts/storage/robin-master-down-10m.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Robin master is down for more than 10 minutes | MQL | `fetch gce_instance \| metric 'custom.googleapis.com/robin/health/status' \| ...` | (Reasoning to be added) | PromQL | (PromQL query to be added) | (Comments to be added) |
