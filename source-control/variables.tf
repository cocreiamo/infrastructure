# Not public (ADR-0008): they come from inputs.enc.yaml.

variable "owner_username" {
  description = "The account of the founder, the only owner of the organization."
  type        = string
}

variable "billing_email" {
  description = "The address the platform sends receipts to."
  type        = string
}

variable "contact_email" {
  description = "The address shown on the profile of the organization."
  type        = string
}
