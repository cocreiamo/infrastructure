# What the organization allows, in every project under it. The baseline
# Google recommends, as found on 2026-11-28.

locals {
  # Constraints that are on or off.
  policies_enforced = toset([
    # No key of a service account exists as a file: the pipeline signs in
    # by federation (ADR-0006, requirement R15).
    "iam.disableServiceAccountKeyCreation",
    "iam.disableServiceAccountKeyUpload",
    # A new project gives its default service accounts no role.
    "iam.automaticIamGrantsForDefaultServiceAccounts",
    # Access to a bucket is granted on the bucket, never object by object.
    "storage.uniformBucketLevelAccess",
    "compute.setNewProjectDefaultToZonalDNSOnly",
  ])

  # Constraints that take a list of what is allowed.
  policies_allowed = {
    # Only accounts of these directories may be given a role.
    "iam.allowedPolicyMemberDomains" = var.workspace_customers
    # Notices of the platform go only to addresses of the company.
    "essentialcontacts.allowedContactDomains"            = ["@cocreiamo.com"]
    "compute.restrictProtocolForwardingCreationForTypes" = ["INTERNAL"]
  }

  # Constraints left open on purpose.
  policies_open = toset([
    "resourcemanager.allowedExportDestinations",
  ])

  policies = setunion(local.policies_enforced, keys(local.policies_allowed), local.policies_open)
}

resource "google_org_policy_policy" "this" {
  for_each = local.policies

  name   = "organizations/${var.organization_id}/policies/${each.key}"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce   = contains(local.policies_enforced, each.key) ? "TRUE" : null
      allow_all = contains(local.policies_open, each.key) ? "TRUE" : null

      dynamic "values" {
        for_each = contains(keys(local.policies_allowed), each.key) ? [local.policies_allowed[each.key]] : []

        content {
          allowed_values = values.value
        }
      }
    }
  }
}
