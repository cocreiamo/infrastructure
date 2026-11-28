# Verifications of the requirements model that the organization answers. They
# plan the unit against a simulated provider: no credential, nothing touched.

mock_provider "google" {}

variables {
  organization_id     = "000000000000"
  owner               = "someone@cocreiamo.com"
  workspace_customers = ["C00000000"]
}

# Part of R15: the platform refuses to create or accept a long-lived key of a
# service account, so none can be stored anywhere. The federation itself is
# in the bootstrap.
run "no_long_lived_key_of_a_service_account" {
  command = plan

  assert {
    condition = alltrue([
      for constraint in ["iam.disableServiceAccountKeyCreation", "iam.disableServiceAccountKeyUpload"] :
      one(google_org_policy_policy.this[constraint].spec[0].rules).enforce == "TRUE"
    ])
    error_message = "Creating and uploading a key of a service account must both be refused."
  }
}

run "roles_only_to_accounts_of_known_directories" {
  command = plan

  assert {
    condition     = one(google_org_policy_policy.this["iam.allowedPolicyMemberDomains"].spec[0].rules).values[0].allowed_values == tolist(var.workspace_customers)
    error_message = "Only accounts of the listed directories may be given a role."
  }
  assert {
    condition     = one(google_org_policy_policy.this["iam.allowedPolicyMemberDomains"].spec[0].rules).allow_all == null
    error_message = "The list of directories must not be open."
  }
}

run "the_owner_is_an_account_of_the_company" {
  command = plan

  variables {
    owner = "someone@example.org"
  }

  expect_failures = [var.owner]
}
