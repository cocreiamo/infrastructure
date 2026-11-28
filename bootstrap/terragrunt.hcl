# Everything the pipeline needs in order to run (ADR-0009). Applied by the
# founder by hand, never by the pipeline: docs/runbooks/bootstrap.md.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# The pipeline runs every unit at once, and this one is not its own to run:
# the identity that plans cannot read what it describes, and no change to
# what the pipeline may do is applied by the pipeline. Run alone, by hand, it
# runs as before.
exclude {
  if      = true
  actions = ["all"]
}

# Identifiers and addresses that are not public (ADR-0008).
inputs = yamldecode(sops_decrypt_file("${get_terragrunt_dir()}/inputs.enc.yaml"))

# What was created by hand on 2026-11-27, before any code, and is adopted
# instead of created (ADR-0009): the project, and its first key ring with the
# keys that re-encrypted the secrets of the previous repository.
#
# GAP-006: these declarations are generated here, and not written next to the
# resources, because the tests of the unit crash on an import block.
generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = <<-IMPORTS
    import {
      to = google_project.this
      id = local.project
    }

    import {
      to = google_kms_key_ring.this["infrastructure"]
      id = "projects/$${local.project}/locations/europe/keyRings/infrastructure"
    }

    import {
      for_each = toset(local.keys["infrastructure"])
      to       = google_kms_crypto_key.this["infrastructure/$${each.key}"]
      id       = "projects/$${local.project}/locations/europe/keyRings/infrastructure/cryptoKeys/$${each.key}"
    }
  IMPORTS
}
