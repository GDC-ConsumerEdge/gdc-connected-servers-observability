# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "duration" {
  description = "How long the condition must persist before alerting. Example: 3600s = 60 min, 1800s = 30 min."
  type        = string
  default     = "3600s"
}

variable "duration_display" {
  description = "Human-readable duration for display names and documentation."
  type        = string
  default     = "60 min"
}

variable "evaluation_interval" {
  description = "How often the condition is checked."
  type        = string
  default     = "60s"
}

variable "rate_window" {
  description = "Window used to calculate vCPU usage rate."
  type        = string
  default     = "5m"
}

variable "lookback_window" {
  description = "How far back to check for previously reporting nodes. Must be longer than duration."
  type        = string
  default     = "180m"
}

variable "node_count_threshold" {
  description = "Minimum number of missing nodes to trigger the multi-node alert."
  type        = number
  default     = 2
}

variable "vcpu_utilization_threshold_percent" {
  description = "vCPU utilization percentage threshold. Alert fires when usage exceeds this value."
  type        = number
  default     = 95
}