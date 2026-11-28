# Verifications of what the organization that hosts the code must hold. They
# plan the unit against a simulated provider: no credential, nothing touched.

mock_provider "github" {}

variables {
  owner_username = "someone"
  billing_email  = "billing@example.org"
  contact_email  = "contact@example.org"
}

# Part of R21: a job gets no more than it asks for.
run "a_workflow_token_reads_by_default" {
  command = plan

  assert {
    condition     = github_actions_organization_workflow_permissions.this.default_workflow_permissions == "read"
    error_message = "The token of a workflow must read by default."
  }
}

run "a_member_creates_no_repository" {
  command = plan

  assert {
    condition = !anytrue([
      github_organization_settings.this.members_can_create_repositories,
      github_organization_settings.this.members_can_create_public_repositories,
      github_organization_settings.this.members_can_create_private_repositories,
    ])
    error_message = "A repository is created by the code, not by a member."
  }
}

run "a_pushed_secret_is_refused_in_every_new_repository" {
  command = plan

  assert {
    condition     = github_organization_settings.this.secret_scanning_push_protection_enabled_for_new_repositories
    error_message = "A new repository must refuse a push that carries a secret."
  }
}
