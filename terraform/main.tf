terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.38.0"
    }
  }
}

provider "google" {
  project = var.project
}

module "control-plane-alerts" {
  count  = var.deploy-alerts ? 1 : 0
  source = "./control-plane"
}

module "node-alerts" {
  count  = var.deploy-alerts ? 1 : 0
  source = "./node"
}

module "pod-alerts" {
  count  = var.deploy-alerts ? 1 : 0
  source = "./pods"
}

module "storage-alerts" {
  count  = var.deploy-alerts ? 1 : 0
  source = "./storage"
}

module "system-alerts" {
  count  = var.deploy-alerts ? 1 : 0
  source = "./system"
}

module "vm-workload-alerts" {
  count  = var.deploy-alerts ? 1 : 0
  source = "./vm-workload"
}

module "dashboards" {
  count  = var.deploy-dashboards ? 1 : 0
  source = "./dashboards"
}
