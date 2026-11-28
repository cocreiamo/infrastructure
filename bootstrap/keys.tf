# The keys (ADR-0004, ADR-0005). Who may decrypt decides the key, and nobody
# holds a copy of one: access is granted here and nowhere else.
#
# A person's sign-in that owns the project can use every key in it, so the
# keys are in two key rings: one whose keys the founder may use, and one that
# a deny policy closes to every person (below).

locals {
  # Key ring -> its keys.
  keys = {
    infrastructure = [
      "state",        # state and saved plans
      "secrets-plan", # credentials that only read, the map of tenants
      "recovery",     # recovery codes of the accounts: the founder only
      # Superseded by the key of the same name in the other key ring, and kept
      # because a key cannot be deleted: it encrypted the write credentials
      # before the bootstrap, and those ciphertexts are in the public history
      # until each credential is replaced at its source.
      "secrets-apply",
    ]
    infrastructure-apply = [
      "secrets-apply", # credentials that can change resources: no person
    ]
  }
  key_names = merge([
    for ring, names in local.keys : { for name in names : "${ring}/${name}" => { ring = ring, name = name } }
  ]...)
}

resource "google_kms_key_ring" "this" {
  for_each = local.keys

  project  = google_project.this.project_id
  name     = each.key
  location = "europe"

  depends_on = [google_project_service.this]
}

# The scanner asks for a new version every 90 days. A year was chosen: every
# version is kept for ever, so each rotation adds a cost that never ends
# (ADR-0004).
# trivy:ignore:GCP-0065
resource "google_kms_crypto_key" "this" {
  for_each = local.key_names

  key_ring = google_kms_key_ring.this[each.value.ring].id
  name     = each.value.name
  purpose  = "ENCRYPT_DECRYPT"

  # A new version each year. Old versions are never destroyed: whatever was
  # last written with one would become unreadable (ADR-0004).
  rotation_period = "31536000s"

  lifecycle {
    prevent_destroy = true
  }
}

# ---- Who uses which key ---------------------------------------------------
# Each binding is the whole list for its role on its key: a member added by
# hand is removed by the next apply.

# State and plans: both identities read the state and write encrypted plans.
resource "google_kms_crypto_key_iam_binding" "state" {
  crypto_key_id = google_kms_crypto_key.this["infrastructure/state"].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = [local.pipeline.plan, local.pipeline.apply]

  depends_on = [google_service_account.pipeline]
}

# Credentials that only read: both identities.
resource "google_kms_crypto_key_iam_binding" "secrets_plan" {
  crypto_key_id = google_kms_crypto_key.this["infrastructure/secrets-plan"].id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  members       = [local.pipeline.plan, local.pipeline.apply]

  depends_on = [google_service_account.pipeline]
}

# Credentials that can change resources: the identity that applies, alone.
resource "google_kms_crypto_key_iam_binding" "secrets_apply" {
  crypto_key_id = google_kms_crypto_key.this["infrastructure-apply/secrets-apply"].id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  members       = [local.pipeline.apply]

  depends_on = [google_service_account.pipeline]
}

# The recovery key and the superseded key have no binding: the pipeline uses
# neither.

# ---- No person decrypts a write credential --------------------------------
# A deny policy wins over every grant, the owner's included. It can be
# attached to a project and narrowed by a tag, and a tag can be put on a key
# ring, not on a key: hence the second key ring.
#
# Its limit (ADR-0005): the owner of the organization can remove the policy.
# That cannot be prevented, only logged.

resource "google_tags_tag_key" "decryption" {
  parent      = "projects/${google_project.this.project_id}"
  short_name  = "decryption"
  description = "Who may decrypt with the keys of a key ring"
}

resource "google_tags_tag_value" "pipeline_only" {
  parent      = google_tags_tag_key.decryption.id
  short_name  = "pipeline-only"
  description = "Only the identity that applies from the main branch"
}

resource "google_tags_location_tag_binding" "apply_key_ring" {
  parent    = "//cloudkms.googleapis.com/${google_kms_key_ring.this["infrastructure-apply"].id}"
  tag_value = google_tags_tag_value.pipeline_only.id
  location  = "europe"
}

resource "google_iam_deny_policy" "write_credentials" {
  provider = google-beta

  parent       = urlencode("cloudresourcemanager.googleapis.com/projects/${google_project.this.project_id}")
  name         = "write-credentials"
  display_name = "No person decrypts a write credential"

  rules {
    description = "Decryption with the keys of a key ring tagged pipeline-only is refused to everyone but the identity that applies."

    deny_rule {
      denied_principals    = ["principalSet://goog/public:all"]
      exception_principals = ["principal://iam.googleapis.com/projects/-/serviceAccounts/${trimprefix(local.pipeline.apply, "serviceAccount:")}"]
      denied_permissions   = ["cloudkms.googleapis.com/cryptoKeyVersions.useToDecrypt"]

      denial_condition {
        title      = "Key rings tagged pipeline-only"
        expression = "resource.matchTagId('${google_tags_tag_key.decryption.id}', '${google_tags_tag_value.pipeline_only.id}')"
      }
    }
  }

  depends_on = [google_service_account.pipeline, google_tags_location_tag_binding.apply_key_ring]
}
