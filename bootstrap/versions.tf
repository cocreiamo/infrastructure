terraform {
  required_version = "1.17.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.12.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "8.12.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
}

# The founder's own sign-in, taken from the environment for the length of a
# command: no credential file is written (docs/runbooks/bootstrap.md).
provider "google" {
  project = local.project
}

provider "google-beta" {
  project = local.project
}

# Some interfaces count their use against a project and refuse a person's
# sign-in that names none: the budget is one.
provider "google" {
  alias                 = "counted"
  project               = local.project
  billing_project       = local.project
  user_project_override = true
}

provider "github" {
  owner = local.github_organization
}
