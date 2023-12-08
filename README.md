# GDCE Enterprise Observability

## Overview

This project contains predefined dashboards and alerts for enterprise workloads running on GDCE.

[Catalog of metrics and alerts](https://docs.google.com/spreadsheets/d/1_C7lXjgDT5ZzhzaWtXm2yp-WevAJk2RexE61veblGt8/edit?resourcekey=0-SvI4CbMsSMwz-ypTlgt5Mg#gid=356051654)

## Alerts Quickstart

### Option 1 - Scripted deployment

1. `cd alerts`
2. Run `./create-alerts.sh`. This will deploy scripts into your current context's project. Modify script if notification channels are needed.

### Option 2 - Terraform deployment

1. cd terraform
2. cp `backend.tf.sample` to `backend.tf` and modify to store tfstate in target cloud storage bucket.
3. `terraform plan`/`teraform apply`

## Dashboards Quickstart

Dashboards are stored in the dashboards folder and can be manually deployed. 