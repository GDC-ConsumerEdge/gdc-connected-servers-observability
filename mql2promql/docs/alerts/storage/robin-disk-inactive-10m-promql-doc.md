# MQL to PromQL Conversion Guide - Robin Disk Inactive 10m

This document explains the proposed translations to Prometheus Query Language (PromQL) of the `alerts/storage/robin-disk-inactive-10m.yaml` alert.

## `alerts/storage/robin-disk-inactive-10m.yaml`

| Group | Input Query Title | Input Query Type | Source Query | LLM Reasoning | LLM Output Query Type | LLM Output PromQL Query | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N/A | Robin disk is inactive for more than 10 minutes | MQL | `fetch gce_instance \| metric 'custom.googleapis.com/robin/health/status' \| ...` | (Reasoning to be added) | PromQL | (PromQL query to be added) | (Comments to be added) |
