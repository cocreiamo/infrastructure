# What the repository needs for the pipeline to sign in (ADR-0006): two
# Environments and the variables that say whom to become. None is a secret.

resource "github_repository_environment" "plan" {
  repository  = local.github_repository
  environment = "plan"
}

# A job enters "apply" only from the main branch, and only after the
# maintainer has approved that run. With one maintainer the approval is a
# deliberate pause, so approving one's own run is allowed.
resource "github_repository_environment" "apply" {
  repository          = local.github_repository
  environment         = "apply"
  can_admins_bypass   = false
  prevent_self_review = false

  reviewers {
    users = [local.github_maintainer_id]
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "apply_from_main" {
  repository     = local.github_repository
  environment    = github_repository_environment.apply.environment
  branch_pattern = "main"
}

resource "github_actions_environment_variable" "identity" {
  for_each = {
    plan  = github_repository_environment.plan.environment
    apply = github_repository_environment.apply.environment
  }

  repository    = local.github_repository
  environment   = each.value
  variable_name = "GOOGLE_SERVICE_ACCOUNT"
  value         = google_service_account.pipeline[each.key].email
}

resource "github_actions_variable" "federation" {
  repository    = local.github_repository
  variable_name = "GOOGLE_WORKLOAD_IDENTITY_PROVIDER"
  value         = module.federation.provider_name
}
