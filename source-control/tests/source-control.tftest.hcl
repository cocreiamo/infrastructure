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

# R20: the main branch changes only through a pull request whose checks
# pass, is never rewritten or deleted, and holds signed commits only.
run "test_R20_main_branch_protected" {
  command = plan

  assert {
    condition = alltrue([
      for name in ["infrastructure-main", "anima-main"] : alltrue([
        github_repository_ruleset.this[name].enforcement == "active",
        github_repository_ruleset.this[name].conditions[0].ref_name[0].include == tolist(["~DEFAULT_BRANCH"]),
        github_repository_ruleset.this[name].rules[0].required_signatures,
        github_repository_ruleset.this[name].rules[0].non_fast_forward,
        github_repository_ruleset.this[name].rules[0].deletion,
        length(github_repository_ruleset.this[name].rules[0].pull_request) == 1,
        length(github_repository_ruleset.this[name].rules[0].required_status_checks[0].required_check) > 0,
      ])
    ])
    error_message = "The main branch must require a pull request, passing checks and signed commits, and refuse rewriting and deletion."
  }
  assert {
    condition     = alltrue([for rule in github_repository_ruleset.this : length(rule.bypass_actors) == 0])
    error_message = "Nobody bypasses a rule."
  }
}
