# The identities of the pipeline (ADR-0006). No key of a service account
# exists: a job exchanges the token GitHub gives it for credentials that last
# minutes.

resource "google_service_account" "pipeline" {
  for_each = {
    plan  = "Reads state and resources for a pull request and for the drift check"
    apply = "Applies an approved plan from the main branch"
  }

  project      = google_project.this.project_id
  account_id   = "pipeline-${each.key}"
  display_name = "pipeline-${each.key}"
  description  = each.value

  depends_on = [google_project_service.this]
}

module "federation" {
  source  = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  version = "6.0.0"

  project_id        = google_project.this.project_id
  pool_id           = "github"
  pool_display_name = "GitHub Actions"
  pool_description  = "Jobs of the infrastructure repository"
  provider_id       = "github"

  # Only a token of this repository, under this owner, is accepted at all.
  attribute_condition = "assertion.repository_id == '${local.github_repository_id}' && assertion.repository_owner_id == '${local.github_owner_id}'"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    # The GitHub Environment the job names, and the same joined to the branch
    # it runs from. A job that names none gets "none" and matches nothing.
    "attribute.environment"        = "has(assertion.environment) ? assertion.environment : 'none'"
    "attribute.environment_at_ref" = "(has(assertion.environment) ? assertion.environment : 'none') + '@' + assertion.ref"
  }

  sa_mapping = {
    # Any job in the Environment "plan": pull requests and the drift check.
    plan = {
      sa_name   = "projects/${local.project}/serviceAccounts/${trimprefix(local.pipeline.plan, "serviceAccount:")}"
      attribute = "attribute.environment/plan"
    }
    # Only a job in the Environment "apply" that runs from the main branch.
    apply = {
      sa_name   = "projects/${local.project}/serviceAccounts/${trimprefix(local.pipeline.apply, "serviceAccount:")}"
      attribute = "attribute.environment_at_ref/apply@refs/heads/main"
    }
  }

  depends_on = [google_service_account.pipeline]
}
