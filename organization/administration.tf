# Who administers the organization: one person (ADR-0006, accepted risk). The
# roles of the two identities of the pipeline are in the bootstrap, so that
# no pull request can widen what the pipeline itself may do (ADR-0009).

locals {
  # As found on 2026-11-28. Each is one grant: a role given by hand to
  # someone else is not removed by this unit, and shows in no plan.
  owner_roles = toset([
    "roles/resourcemanager.organizationAdmin",
    "roles/resourcemanager.folderCreator",
    "roles/resourcemanager.projectCreator",
    "roles/resourcemanager.projectDeleter",
    "roles/orgpolicy.policyAdmin",
    "roles/billing.admin",
    "roles/billing.user",
    # Writes the policy that closes the write credentials to every person
    # (ADR-0005): the bootstrap needs it.
    "roles/iam.denyAdmin",
    "roles/iam.workforcePoolAdmin",
    "roles/assuredworkloads.admin",
  ])
}

resource "google_organization_iam_member" "owner" {
  for_each = local.owner_roles

  org_id = var.organization_id
  role   = each.key
  member = "user:${var.owner}"

  # Removing one could lock the only owner out of the organization.
  lifecycle {
    prevent_destroy = true
  }
}

# What Google itself sends about the organization: security, billing, legal,
# suspension, technical notices.
resource "google_essential_contacts_contact" "owner" {
  parent                              = "organizations/${var.organization_id}"
  email                               = var.owner
  language_tag                        = "it"
  notification_category_subscriptions = ["ALL"]
}

# The projects of the tenants live under it (ADR-0011).
resource "google_folder" "ventures" {
  display_name = "ventures"
  parent       = "organizations/${var.organization_id}"

  lifecycle {
    prevent_destroy = true
  }
}
