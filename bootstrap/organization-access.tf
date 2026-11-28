# What the two identities may do outside their own project. It is decided
# here, in the unit the pipeline never applies, so that no pull request can
# widen what the pipeline itself may do (ADR-0009).

locals {
  # Reading: enough to compare the code with what exists.
  organization_roles_read = [
    "roles/browser",                         # organization, folders, projects
    "roles/iam.securityReviewer",            # every access policy
    "roles/orgpolicy.policyViewer",          # the policies of the organization
    "roles/essentialcontacts.viewer",        # who is told what
    "roles/serviceusage.serviceUsageViewer", # which interfaces are on
    "roles/billing.viewer",                  # which project is paid by which account
  ]

  # Changing: what the units of the organization describe, and no more.
  organization_roles_change = [
    "roles/resourcemanager.organizationAdmin", # access policy of the organization
    "roles/resourcemanager.folderAdmin",       # folders and their access policies
    "roles/resourcemanager.projectCreator",    # a project for a new tenant
    "roles/orgpolicy.policyAdmin",             # the policies of the organization
    "roles/essentialcontacts.admin",           # who is told what
    "roles/serviceusage.serviceUsageAdmin",    # which interfaces are on
    "roles/billing.user",                      # link a project to the billing account
  ]

  organization_access = merge(
    { for role in local.organization_roles_read : "plan ${role}" => { identity = "plan", role = role } },
    { for role in concat(local.organization_roles_read, local.organization_roles_change) : "apply ${role}" => { identity = "apply", role = role } },
  )
}

# The scanner reports the administrator roles. They are the point: the
# identity that applies an approved plan from the main branch is the one
# that administers, and the identity of a pull request holds none of them.
# trivy:ignore:GCP-0007
resource "google_organization_iam_member" "pipeline" {
  for_each = local.organization_access

  org_id = var.organization_id
  role   = each.value.role
  member = local.pipeline[each.value.identity]

  depends_on = [google_service_account.pipeline]
}

# The workspace is reached by acting for its administrator, which an identity
# does by signing a request with its own name: each may do so for itself only.
resource "google_service_account_iam_member" "signs_for_itself" {
  for_each = local.pipeline

  service_account_id = "projects/${local.project}/serviceAccounts/${trimprefix(each.value, "serviceAccount:")}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = each.value

  depends_on = [google_service_account.pipeline]
}

# Each call of an interface is counted against a project: this one.
resource "google_project_iam_member" "counted_here" {
  for_each = local.pipeline

  project = google_project.this.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = each.value

  depends_on = [google_service_account.pipeline]
}
