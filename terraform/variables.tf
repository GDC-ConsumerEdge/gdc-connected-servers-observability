variable "project" {
  type        = string
  description = "GCP Project Name"
}

variable "deploy-alerts" {
  type        = bool
  description = "Deploy alerts"
  default     = true
}

variable "deploy-dashboards" {
  type        = bool
  description = "Deploy dashboards"
  default     = true
}