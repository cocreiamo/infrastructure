# The rules of the protected branches (requirement R20): a branch changes
# only through a pull request whose checks pass, its history is never
# rewritten or deleted, and every commit on it is signed. As found on
# 2026-11-28. Nobody bypasses a rule: no actor is listed.
#
# The settings of a repository are not here: the platform shows how a
# repository merges pull requests only to an identity that can write to it,
# and the identity that plans cannot (configured-by-hand.yaml).

locals {
  rules = {
    # This repository: squash only, on a branch that is up to date.
    infrastructure-main = {
      repository    = "infrastructure"
      name          = "main"
      branches      = ["~DEFAULT_BRANCH"]
      merge_methods = ["squash"]
      checks        = ["check", "Conventional Commits title", "Dependency review"]
      up_to_date    = true
      queue         = false
    }
    # The product: merged through a queue, which tests each change on top of
    # the ones before it.
    anima-main = {
      repository    = "anima"
      name          = "main"
      branches      = ["~DEFAULT_BRANCH"]
      merge_methods = ["merge", "squash", "rebase"]
      checks = [
        "check / check",
        "reuse / reuse",
        "pull-request / Conventional Commits title",
        "pull-request / Dependency review",
      ]
      up_to_date = false
      queue      = true
    }
    # The last commit of the product that passed every check: moved forward
    # by a workflow, never through a pull request.
    anima-main-green = {
      repository    = "anima"
      name          = "main-green"
      branches      = ["refs/heads/main-green"]
      merge_methods = null
      checks        = []
      up_to_date    = false
      queue         = false
    }
  }
}

resource "github_repository_ruleset" "this" {
  for_each = local.rules

  repository  = each.value.repository
  name        = each.value.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = each.value.branches
      exclude = []
    }
  }

  rules {
    required_signatures = true
    non_fast_forward    = true
    deletion            = true

    # No approval is required: the only maintainer cannot approve their own
    # pull request (ADR-0006). Open conversations are resolved first.
    dynamic "pull_request" {
      for_each = each.value.merge_methods == null ? [] : [each.value.merge_methods]

      content {
        allowed_merge_methods             = pull_request.value
        required_approving_review_count   = 0
        required_review_thread_resolution = true
        dismiss_stale_reviews_on_push     = false
        require_code_owner_review         = false
        require_last_push_approval        = false
      }
    }

    dynamic "required_status_checks" {
      for_each = length(each.value.checks) > 0 ? [each.value.checks] : []

      content {
        strict_required_status_checks_policy = each.value.up_to_date
        do_not_enforce_on_create             = false

        dynamic "required_check" {
          for_each = required_status_checks.value

          content {
            context = required_check.value
          }
        }
      }
    }

    dynamic "merge_queue" {
      for_each = each.value.queue ? [1] : []

      content {
        merge_method                      = "SQUASH"
        grouping_strategy                 = "ALLGREEN"
        check_response_timeout_minutes    = 60
        max_entries_to_build              = 5
        max_entries_to_merge              = 5
        min_entries_to_merge              = 1
        min_entries_to_merge_wait_minutes = 0
      }
    }
  }
}
