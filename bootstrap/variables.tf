# Values that are not public. They come encrypted from inputs.enc.yaml.

variable "organization_id" {
  description = "Numeric id of the Google Cloud organization that owns the project."
  type        = string
}

variable "billing_account" {
  description = "Id of the billing account that pays for the project."
  type        = string
}

variable "contacts" {
  description = "Addresses told about spending and about the suspension of the project: the maintainer first, then every other person."
  type        = list(string)

  validation {
    condition     = length(var.contacts) >= 1 && length(distinct(var.contacts)) == length(var.contacts)
    error_message = "At least one contact is needed, and none twice."
  }
}

variable "monthly_budget" {
  description = "Spending of the billing account in a month, in its own currency, above which the contacts are told."
  type        = number
  default     = 10
}

locals {
  project             = "cocreiamo-infrastructure"
  github_organization = "cocreiamo"
  github_repository   = "infrastructure"

  # Numeric ids of the repository and of its owner: a federation bound to
  # them survives a rename and cannot be taken over by a new owner of the name.
  github_repository_id = "1474580731"
  github_owner_id      = "220197847"
  # The maintainer's account, the only one that approves a run that applies.
  github_maintainer_id = 81918410

  # The two identities of the pipeline (ADR-0006), known before they exist.
  pipeline = {
    plan  = "serviceAccount:pipeline-plan@${local.project}.iam.gserviceaccount.com"
    apply = "serviceAccount:pipeline-apply@${local.project}.iam.gserviceaccount.com"
  }
}
