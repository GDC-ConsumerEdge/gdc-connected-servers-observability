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
  description = "Window used to calculate latency rates."
  type        = string
  default     = "5m"
}

variable "read_latency_threshold_usecs" {
  description = "Read latency threshold in microseconds. Example: 200000 = 200ms, 100000 = 100ms."
  type        = number
  default     = 200000
}

variable "read_latency_threshold_display" {
  description = "Human-readable read latency threshold for display names and documentation."
  type        = string
  default     = "200ms"
}

variable "write_latency_threshold_usecs" {
  description = "Write latency threshold in microseconds. Example: 400000 = 400ms, 200000 = 200ms."
  type        = number
  default     = 400000
}

variable "write_latency_threshold_display" {
  description = "Human-readable write latency threshold for display names and documentation."
  type        = string
  default     = "400ms"
}

variable "free_space_threshold_percent" {
  description = "Free space percentage threshold. Alert fires when free space drops below this value."
  type        = number
  default     = 5
}