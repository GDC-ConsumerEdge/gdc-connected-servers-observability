terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.1.0"
    }
  }
}

provider "google" {
  project = var.project
}

module "control-plane-alerts" {
  source = "./control-plane"
}

module "node-alerts" {
  source = "./node"
}

module "pod-alerts" {
  source = "./pods"
}

module "storage-alerts" {
  source = "./storage"
}

module "system-alerts" {
  source = "./system"
}

module "vm-workload-alerts" {
  source = "./vm-workload"
}