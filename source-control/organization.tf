# The settings of the organization, as found on 2026-11-28. What the
# platform offers no interface for is in configured-by-hand.yaml.

resource "github_organization_settings" "this" {
  name          = "Cocreiamo"
  billing_email = var.billing_email
  email         = var.contact_email
  blog          = "https://cocreiamo.com"
  location      = "Italy"

  # A repository is created by this code, not by a member.
  default_repository_permission           = "read"
  members_can_create_repositories         = false
  members_can_create_public_repositories  = false
  members_can_create_private_repositories = false
  members_can_fork_private_repositories   = false
  # Public sites only.
  members_can_create_pages         = true
  members_can_create_public_pages  = true
  members_can_create_private_pages = false
  web_commit_signoff_required      = false
  has_organization_projects        = true
  has_repository_projects          = true

  # What every new repository starts with: alerts on its dependencies, pull
  # requests for their security updates, and a push that carries a secret
  # is refused.
  advanced_security_enabled_for_new_repositories               = false
  dependabot_alerts_enabled_for_new_repositories               = true
  dependabot_security_updates_enabled_for_new_repositories     = true
  dependency_graph_enabled_for_new_repositories                = true
  secret_scanning_enabled_for_new_repositories                 = true
  secret_scanning_push_protection_enabled_for_new_repositories = true
}

# Which actions a workflow may use. Every workflow of ours pins its actions
# by commit; the platform does not require it yet, because not every
# repository of the organization does.
resource "github_actions_organization_permissions" "this" {
  enabled_repositories = "all"
  allowed_actions      = "all"
  sha_pinning_required = false
}

# The token a workflow gets reads by default: a job asks for more in its own
# permissions (R21). A workflow may open and approve a pull request, as
# found; whether it stays so is an open question of the repository's issues.
resource "github_actions_organization_workflow_permissions" "this" {
  organization_slug                = local.organization
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = true
}

# One owner (ADR-0006, accepted risk).
resource "github_membership" "owner" {
  username = var.owner_username
  role     = "admin"

  # Removing it would leave the organization without an owner.
  lifecycle {
    prevent_destroy = true
  }
}
