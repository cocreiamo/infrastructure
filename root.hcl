# What every unit shares: where its state lives and how it is encrypted
# (ADR-0004). A unit includes this file and gets its own state under its own
# path. No unit declares a backend or an encryption block itself.

locals {
  project      = "cocreiamo-infrastructure"
  state_bucket = "cocreiamo-infrastructure-state"
  state_key    = "projects/${local.project}/locations/europe/keyRings/infrastructure/cryptoKeys/state"

  backend_bucket = <<-BUCKET
    terraform {
      backend "gcs" {
        bucket = "${local.state_bucket}"
        prefix = "${path_relative_to_include()}"
      }
    }
  BUCKET
  backend_local  = <<-LOCAL
    terraform {
      backend "local" {
        path = "${get_repo_root()}/.cache/state/${path_relative_to_include()}.tfstate"
      }
    }
  LOCAL
}

# Only the bootstrap uses it, and only for its first apply, when the state
# bucket does not exist yet (docs/runbooks/bootstrap.md).
feature "local_state" {
  default = false
}

terraform {
  # The unit is copied into the cache before it runs, so that nothing
  # generated or downloaded is written next to the code.
  source = "${get_terragrunt_dir()}//."
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = feature.local_state.value ? local.backend_local : local.backend_bucket
}

# State and saved plans are encrypted on the machine that produces them, with
# a key that never leaves the key service; a state or plan in clear is refused.
generate "encryption" {
  path      = "encryption.tf"
  if_exists = "overwrite"
  contents  = <<-ENCRYPTION
    terraform {
      encryption {
        key_provider "gcp_kms" "state" {
          kms_encryption_key = "${local.state_key}"
          key_length         = 32
        }
        method "aes_gcm" "state" {
          keys = key_provider.gcp_kms.state
        }
        state {
          method   = method.aes_gcm.state
          enforced = true
        }
        plan {
          method   = method.aes_gcm.state
          enforced = true
        }
      }
    }
  ENCRYPTION
}
