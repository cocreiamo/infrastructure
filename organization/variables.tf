# Not public (ADR-0008): they come from inputs.enc.yaml.

variable "organization_id" {
  description = "The number of the Google Cloud organization."
  type        = string
}

variable "owner" {
  description = "The address of the founder's account, the only person who administers the organization."
  type        = string

  validation {
    condition     = endswith(var.owner, "@cocreiamo.com")
    error_message = "The owner is an account of the company."
  }
}

variable "workspace_customers" {
  description = "The directories whose accounts may be given a role in the organization."
  type        = list(string)

  validation {
    condition     = length(var.workspace_customers) > 0
    error_message = "At least the company's own directory."
  }
}
