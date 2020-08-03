//---------------------------------------------------------------------- terraform / backend
terraform {
  required_version = "~>0.12.0"
}
//---------------------------------------------------------------------- provider
provider "google" {
  version = "~>3.0.0"
  project = var.project
  region  = var.region
}
//---------------------------------------------------------------------- firewall rules for kubernetes nodeports
resource "google_compute_firewall" "kubernetes-nodeports" {
  name    = "kubernetes-nodeports-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }
}
//---------------------------------------------------------------------- firewall rules for ui
resource "google_compute_firewall" "search-engine-ui" {
  name    = "search-engine-ui"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}
//---------------------------------------------------------------------- kubernetes cluster
resource "google_container_cluster" "kubernetes-cluster" {
  name               = var.cluster_name
  location           = var.zone != "" ? var.zone : var.region
  network            = "default"
  initial_node_count = var.node_count
  enable_legacy_abac = var.legacy_authorization

  master_auth {
    //// Basic authentication is disabled
    // username = ""
    // password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.node_disk_size_gb

    oauth_scopes = var.oauth_scopes

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}
