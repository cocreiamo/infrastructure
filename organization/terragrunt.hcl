# Who administers the Google Cloud organization and what it allows (ADR-0003).
# Everything here existed before the code and is adopted, not created.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  # Identifiers and addresses that are not public (ADR-0008).
  private = yamldecode(sops_decrypt_file("${get_terragrunt_dir()}/inputs.enc.yaml"))
}

inputs = {
  organization_id     = local.private.organization_id
  owner               = local.private.owner
  workspace_customers = local.private.workspace_customers
}

# What is adopted, declared as code and applied by the pipeline (R23).
#
# GAP-006: these declarations are generated here, and not written next to the
# resources, because the tests of the unit crash on an import block.
generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = <<-IMPORTS
    import {
      for_each = local.owner_roles
      to       = google_organization_iam_member.owner[each.key]
      id       = "$${var.organization_id} $${each.key} user:$${var.owner}"
    }

    import {
      for_each = local.policies
      to       = google_org_policy_policy.this[each.key]
      id       = "organizations/$${var.organization_id}/policies/$${each.key}"
    }

    import {
      to = google_essential_contacts_contact.owner
      id = "organizations/$${var.organization_id}/contacts/${local.private.owner_contact}"
    }

    import {
      to = google_folder.ventures
      id = "folders/${local.private.ventures_folder}"
    }
  IMPORTS
}
