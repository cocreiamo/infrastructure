# The organization that hosts the code: its settings, what its workflows may
# do and who administers it (ADR-0003). Everything here existed before the
# code and is adopted, not created.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Addresses and the name of an account, which are not public (ADR-0008).
inputs = yamldecode(sops_decrypt_file("${get_terragrunt_dir()}/inputs.enc.yaml"))

# What is adopted, declared as code and applied by the pipeline (R23).
#
# GAP-006: these declarations are generated here, and not written next to the
# resources, because the tests of the unit crash on an import block.
generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = <<-IMPORTS
    import {
      to = github_organization_settings.this
      id = local.organization
    }

    import {
      to = github_actions_organization_permissions.this
      id = local.organization
    }

    import {
      to = github_actions_organization_workflow_permissions.this
      id = local.organization
    }

    import {
      to = github_membership.owner
      id = "$${local.organization}:$${var.owner_username}"
    }

    import {
      for_each = {
        infrastructure-main = "28245499"
        anima-main          = "28234939"
        anima-main-green    = "28238193"
      }
      to = github_repository_ruleset.this[each.key]
      id = "$${local.rules[each.key].repository}:$${each.value}"
    }
  IMPORTS
}
