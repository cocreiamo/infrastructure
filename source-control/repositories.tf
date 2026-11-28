# The public repositories of the organization. What differs from one to the
# other is in repositories.yaml; what they share is here. The private ones
# are not here: a tenant's belong to its own unit (ADR-0011).

locals {
  repositories = yamldecode(file("${path.module}/repositories.yaml"))
}

resource "github_repository" "this" {
  for_each = local.repositories

  name         = each.key
  description  = each.value.description
  homepage_url = each.value.homepage
  visibility   = "public"

  has_issues      = each.value.issues
  has_wiki        = each.value.wiki
  has_projects    = each.value.projects
  has_discussions = false

  # How a pull request is merged.
  allow_squash_merge          = true
  allow_merge_commit          = each.value.merge_commit
  allow_rebase_merge          = each.value.rebase
  allow_auto_merge            = false
  allow_update_branch         = false
  delete_branch_on_merge      = each.value.delete_branch
  web_commit_signoff_required = each.value.signoff

  # A fork is a mirror of someone else's repository: it is created from it.
  fork         = can(each.value.fork_of) ? true : null
  source_owner = can(each.value.fork_of) ? split("/", each.value.fork_of)[0] : null
  source_repo  = can(each.value.fork_of) ? split("/", each.value.fork_of)[1] : null

  # A push that carries a secret is refused where our own code lives.
  security_and_analysis {
    secret_scanning {
      status = each.value.secret_scanning ? "enabled" : "disabled"
    }
    secret_scanning_push_protection {
      status = each.value.secret_scanning ? "enabled" : "disabled"
    }
  }

  # A repository is never deleted from here: its history and its issues
  # would go with it.
  lifecycle {
    prevent_destroy = true
  }
}
