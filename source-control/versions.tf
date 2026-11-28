terraform {
  required_version = "1.17.2"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
}

locals {
  organization = "cocreiamo"
}

# The credential is a GitHub App of the organization, taken from the
# environment (GITHUB_APP_ID, GITHUB_APP_INSTALLATION_ID,
# GITHUB_APP_PEM_FILE): the App that only reads when a plan is made, the one
# that changes when a plan is applied (ADR-0005). The empty block says that
# an App is used.
provider "github" {
  owner = local.organization

  app_auth {}
}
