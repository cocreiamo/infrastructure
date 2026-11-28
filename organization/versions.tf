terraform {
  required_version = "1.17.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.12.0"
    }
  }
}

# The credential comes from the environment: the identity of the job on a
# runner, the maintainer's own sign-in on their machine. The interfaces of
# the organization count their use against a project, and a person's sign-in
# names none by itself.
provider "google" {
  project               = "cocreiamo-infrastructure"
  billing_project       = "cocreiamo-infrastructure"
  user_project_override = true
}
