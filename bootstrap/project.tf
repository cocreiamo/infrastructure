# The project that holds state and keys. Created by hand on 2026-11-27 and
# adopted here (ADR-0009).

resource "google_project" "this" {
  project_id      = local.project
  name            = "infrastructure"
  org_id          = var.organization_id
  billing_account = var.billing_account
  deletion_policy = "PREVENT"

  # The project runs no machine and needs no network.
  auto_create_network = false

  lifecycle {
    prevent_destroy = true
  }
}

# Losing the project loses state and keys together: nobody deletes it, by
# mistake or through a change, without first removing this lien by hand.
resource "google_resource_manager_lien" "project" {
  parent       = "projects/${google_project.this.number}"
  origin       = "cocreiamo-infrastructure-bootstrap"
  reason       = "Holds the state and the keys of the whole infrastructure"
  restrictions = ["resourcemanager.projects.delete"]
}

locals {
  services = toset([
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "essentialcontacts.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "monitoring.googleapis.com",
    "orgpolicy.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ])
}

resource "google_project_service" "this" {
  for_each = local.services

  project            = google_project.this.project_id
  service            = each.key
  disable_on_destroy = false
}

# Every use of a key and every read or write of the state store is logged:
# who did what and when, reads included.
resource "google_project_iam_audit_config" "all" {
  project = google_project.this.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
