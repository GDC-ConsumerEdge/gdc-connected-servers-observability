# GDCE Enterprise Observability

## Overview

This project contains predefined dashboards and alerts for enterprise workloads running on GDCE.

[Catalog of metrics and alerts](https://docs.google.com/spreadsheets/d/1_C7lXjgDT5ZzhzaWtXm2yp-WevAJk2RexE61veblGt8/edit?resourcekey=0-SvI4CbMsSMwz-ypTlgt5Mg#gid=356051654)

## Deployment Quickstart

### Option 1 - Scripted deployment

1. `cd alerts`
2. Run `./create-alerts.sh`. This will deploy scripts into your current context's project. Modify script if notification channels are needed.

Dashboards are stored in the dashboards folder and can be manually deployed. 

### Option 2 - Terraform deployment

1. cd terraform
2. cp `backend.tf.sample` to `backend.tf` and modify to store tfstate in target cloud storage bucket.
3. `terraform plan`/`teraform apply`

## Dashboards

| Dashboard Name       | Screenshot                                                          | Description                                                                                                      | json                      |
| :------------------- | :------------------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------------- | :------------------------ |
| GDC Daily Report     | ![dashboard](https://screenshot.googleplex.com/88LfuskJEZEsCT.png)  | Dashboard showing node/VM availability and utilization based metrics                                             | http://shortn/_VIqO4f1jcR |
| GDC Logs             | ![dashboard](https://screenshot.googleplex.com/8qfZ5nZRFj6A5vL.png) | Dashboard with example Cloud Logging queries                                                                     | http://shortn/_fPNHz5DCwU |
| GDC Node View        | ![dashboard](https://screenshot.googleplex.com/4dRntZGgHvTgTNN.png) | Dashboard showing GDC node information                                                                           | http://shortn/_LtfVMTWAIj |
| GDC VM Status        | ![dashboard](https://screenshot.googleplex.com/Bzwxw8kX5pmUp8b.png) | Dashboard showing GDC VM information                                                                             | http://shortn/_Vlfh4TeYlG |
| GDC Robin Status     | ![dashboard](https://screenshot.googleplex.com/8grZWZsgZDzdzRW.png) | Dashboard to deep-dive into robin metrics. Note: this dashboard requires the use of the robin-health application | http://shortn/_K3mEEncvls |
| GDC External Secrets | ![dashboard](https://screenshot.googleplex.com/4YEWwskAhBAGQCf.png) | Dashboard showing External Secrets operational information                                                       | http://shortn/_ZikQEfILoq |


## Alerts

| node-cpu-usage-high                  | Node            | Alert when CPU usage of any node exceeds 80%                      | http://shortn/_DzJ1aQcl3P |
| :----------------------------------- | :-------------- | :---------------------------------------------------------------- | :------------------------ |
| node-memory-usage-high               | Node            | Alert when memory usage of any node exceeds 80%                   | http://shortn/_GZXuqeWVhs |
| node-not-ready-30m                   | Node            | Alert if any node is not ready for more than 30 minutes           | http://shortn/_fMYWpmM9PW |
| multiple-nodes-not-ready-realtime    | Node            | Alert if multiple nodes are not ready at any time                 | http://shortn/_yWqKOlTCd5 |
| api-server-error-ratio-5-percent     | Control-plane   | Alert if the API server has an error ratio exceeding 5%           | http://shortn/_afiRU0qn7w |
| apiserver-down                       | Control-plane   | Alert if api server is down                                       | http://shortn/_M0WSfJ9eGE |
| controller-manager-down              | Control-plane   | Alert if controller manager is down                               | http://shortn/_fAh9Ja3Lxb |
| scheduler-down                       | Control-plane   | Alert if scheduler is down                                        | http://shortn/_DSief6OQJP |
| pod-crash-looping                    | Pods            | Alert if a pod is crashlooping                                    | http://shortn/_GqgRYTqGh7 |
| pod-not-ready-1h                     | Pods            | Alert if a pod is not ready for more than an hour                 | http://shortn/_kOsVFOUQIx |
| coredns-down                         | System          | Alert if CoreDNS is down                                          | http://shortn/_6yCd6bvpLZ |
| coredns-servfail-ratio-1-percent     | System          | Alert if greater than 1 percent of DNS requests are SERVFAILs     | http://shortn/_GGbtLHRTdh |
| robin-master-down-10m                | Storage         | Alert if robin master is down for more than 10 minutes            | http://shortn/_MO4IdGC8qB |
| robin-node-offline-30m               | Storage         | Alert if a robin node is offline for more than 30 minutes         | http://shortn/_HpHwjkIxLI |
| robin-disk-inactive-10m              | Storage         | Alert if robin disk is inactive for more than 10 minutes          | http://shortn/_5cHpRszFJE |
| vmruntime-heartbeats-active-realtime | VMRuntime       | Alert if VMRuntime heartbeats are missing                         | http://shortn/_R3jK5d8Shz |
| vmruntime-heartbeats-realtime        | VMRuntime       | Alert if VMRuntime heartbeats are 0                               | http://shortn/_LVAcHK0dfK |
| vmruntime-vm-down-5m                 | VMRuntime       | Alert if any VM is not active for more than 5 minutes             | http://shortn/_RuClarQiRa |
| vmruntime-vm-missing-5m              | VMRuntime       | Alert if CPU activity for a VM are absent for more than 5 minutes | http://shortn/_npLmj6WJxh |
| vmruntime-vm-no-network-traffic-5m   | VMRuntime       | Alert if there is no network activity from a VM                   | http://shortn/_5Igz1mccVb |
| externalsecrets-down-30m             | ExternalSecrets | Alert if External Secrets is down                                 | http://shortn/_C11FLfAeXz |
| externalsecrets-sync-error           | ExternalSecrets | Alert if any ExternalSecret resources have sync errors            | http://shortn/_6H3GMemc85 |