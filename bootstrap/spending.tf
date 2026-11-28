# Billing is the most likely way to lose everything over the years: a card
# expires, the project is suspended and then removed with state and keys
# (ADR-0009). Two people are told, by two routes.

resource "google_monitoring_notification_channel" "contact" {
  count = length(var.contacts)

  project      = google_project.this.project_id
  display_name = "Spending contact ${count.index + 1}"
  type         = "email"
  labels       = { email_address = var.contacts[count.index] }

  depends_on = [google_project_service.this]
}

# The whole billing account, not this project alone: anything that spends
# is a surprise here.
resource "google_billing_budget" "account" {
  provider = google.counted

  billing_account = var.billing_account
  display_name    = "Whole account, monthly"

  budget_filter {
    calendar_period        = "MONTH"
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      units = tostring(var.monthly_budget)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = google_monitoring_notification_channel.contact[*].id
    disable_default_iam_recipients   = false
  }

  depends_on = [google_project_service.this]
}

# What Google itself sends about billing and about a suspension of the
# project reaches both people too.
resource "google_essential_contacts_contact" "contact" {
  count = length(var.contacts)

  parent                              = "projects/${google_project.this.project_id}"
  email                               = var.contacts[count.index]
  language_tag                        = "en"
  notification_category_subscriptions = ["BILLING", "SUSPENSION"]

  depends_on = [google_project_service.this]
}
