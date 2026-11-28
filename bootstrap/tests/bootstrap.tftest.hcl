# Verifications of the requirements model that the bootstrap answers. Each run
# is named like its verification in model/infrastructure.sysml. They plan the
# unit against providers that are simulated: no credential, nothing touched.

mock_provider "google" {}
mock_provider "google" {
  alias = "counted"
}
mock_provider "google-beta" {}
mock_provider "github" {}

variables {
  organization_id = "000000000000"
  billing_account = "000000-000000-000000"
  contacts        = ["first@example.org", "second@example.org"]
}

# Part of R9. The requirement asks for a second contact, and today there is
# only the maintainer: its verification stays pending until a second person
# is added to the inputs.
run "spending_is_reported_to_every_contact" {
  command = plan

  assert {
    condition     = length(google_monitoring_notification_channel.contact) == length(var.contacts)
    error_message = "Every contact must have a channel."
  }
  assert {
    condition     = length(google_billing_budget.account.all_updates_rule[0].monitoring_notification_channels) == length(var.contacts)
    error_message = "The budget must notify every contact."
  }
  assert {
    condition     = length(google_essential_contacts_contact.contact) == length(var.contacts)
    error_message = "The platform's own billing notices must reach every contact."
  }
}

run "no_contact_is_refused" {
  command = plan

  variables {
    contacts = []
  }

  expect_failures = [var.contacts]
}

run "test_R11_state_store_not_public" {
  command = plan

  assert {
    condition     = google_storage_bucket.state.public_access_prevention == "enforced"
    error_message = "It must not be possible to make the content of the state store public."
  }
  assert {
    condition     = google_storage_bucket.state.uniform_bucket_level_access
    error_message = "Access to the state store must be decided for the whole bucket, not object by object."
  }
}

run "test_R16_1_pull_request_cannot_decrypt_write_secrets" {
  command = plan

  assert {
    condition     = google_kms_crypto_key_iam_binding.secrets_apply.members == toset([local.pipeline.apply])
    error_message = "Only the identity that applies may decrypt the write credentials."
  }
  assert {
    condition     = google_iam_deny_policy.write_credentials.rules[0].deny_rule[0].exception_principals == tolist(["principal://iam.googleapis.com/projects/-/serviceAccounts/pipeline-apply@${local.project}.iam.gserviceaccount.com"])
    error_message = "The only exception to the denial must be the identity that applies."
  }
  assert {
    condition     = contains(google_iam_deny_policy.write_credentials.rules[0].deny_rule[0].denied_permissions, "cloudkms.googleapis.com/cryptoKeyVersions.useToDecrypt")
    error_message = "Decryption of the write credentials must be denied to everyone else."
  }
}

run "test_R16_2_pull_request_cannot_write_state" {
  command = plan

  assert {
    condition     = google_storage_bucket_iam_binding.read.members == toset([local.pipeline.plan]) && google_storage_bucket_iam_binding.read.role == "roles/storage.objectViewer"
    error_message = "The identity of a pull request may only read the state store."
  }
  assert {
    condition     = google_storage_bucket_iam_binding.write.members == toset([local.pipeline.apply])
    error_message = "Only the identity that applies may write the state store."
  }
}

run "test_R17_apply_only_from_main_after_approval" {
  command = plan

  assert {
    condition     = length(github_repository_environment.apply.reviewers[0].users) == 1
    error_message = "A run that applies must wait for the maintainer's approval."
  }
  assert {
    condition     = github_repository_environment.apply.can_admins_bypass == false
    error_message = "Nobody may skip the approval."
  }
  assert {
    condition     = github_repository_environment.apply.deployment_branch_policy[0].custom_branch_policies && github_repository_environment_deployment_policy.apply_from_main.branch_pattern == "main"
    error_message = "Only the main branch may enter the Environment that applies."
  }
}

run "test_R31_earlier_state_restorable" {
  command = plan

  assert {
    condition     = google_storage_bucket.state.versioning[0].enabled
    error_message = "The state store must keep earlier versions."
  }
  assert {
    condition     = alltrue([for rule in google_storage_bucket.state.lifecycle_rule : one(rule.condition).days_since_noncurrent_time >= 90 if one(rule.action).type == "Delete"])
    error_message = "No earlier version may be removed before 90 days."
  }
}

# Part of R16: the identity of a pull request holds no role that changes
# anything outside its own project either.
run "pull_request_identity_only_reads_the_organization" {
  command = plan

  assert {
    condition = alltrue([
      for access in google_organization_iam_member.pipeline :
      contains(local.organization_roles_read, access.role) if access.member == local.pipeline.plan
    ])
    error_message = "The identity of a pull request may only hold roles that read."
  }
  assert {
    condition = alltrue([
      for role in local.organization_roles_read :
      endswith(role, "iewer") || endswith(role, "eviewer") || role == "roles/browser"
    ])
    error_message = "A role that reads must be a viewer role."
  }
}
