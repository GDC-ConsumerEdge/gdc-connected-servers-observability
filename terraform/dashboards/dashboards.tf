locals {
  dashboard_files = fileset(path.module, "*.json") 
}

resource "google_monitoring_dashboard" "dashboard" {
  for_each = local.dashboard_files

  dashboard_json = file("${path.module}/${each.value}")
}