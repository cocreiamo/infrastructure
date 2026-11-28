# The state store (ADR-0004): one private bucket. What is written to it is
# already encrypted by OpenTofu (root.hcl); the bucket never sees a state in
# clear.

# The scanner asks for a key of ours on the bucket and for its access log in
# a second bucket. The content is encrypted with a key of ours before it
# arrives, and every access is in the audit log of the project (project.tf).
# trivy:ignore:GCP-0066
# trivy:ignore:GCP-0077
resource "google_storage_bucket" "state" {
  project  = google_project.this.project_id
  name     = "cocreiamo-infrastructure-state"
  location = "EU"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Every write keeps the version before it.
  versioning {
    enabled = true
  }

  # An earlier version goes only when it is both older than a year and
  # followed by at least ten newer ones.
  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 365
      num_newer_versions         = 10
      with_state                 = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.this]
}

# A pull request reads the state and cannot write it; only the identity that
# applies writes. Each binding is the whole list for its role.
resource "google_storage_bucket_iam_binding" "read" {
  bucket  = google_storage_bucket.state.name
  role    = "roles/storage.objectViewer"
  members = [local.pipeline.plan]

  depends_on = [google_service_account.pipeline]
}

resource "google_storage_bucket_iam_binding" "write" {
  bucket  = google_storage_bucket.state.name
  role    = "roles/storage.objectUser"
  members = [local.pipeline.apply]

  depends_on = [google_service_account.pipeline]
}
