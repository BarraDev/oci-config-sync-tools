# =============================================================================
# 1PASSWORD PROVIDER CONFIGURATION
# =============================================================================

provider "onepassword" {
  # Service account token can be set via OP_SERVICE_ACCOUNT_TOKEN env var
  service_account_token = var.service_account_token != "" ? var.service_account_token : null
  account               = var.account != "" ? var.account : null
}

# =============================================================================
# LOAD ITEM FROM 1PASSWORD
# =============================================================================

data "onepassword_item" "config" {
  vault = var.vault_name
  title = var.item_name
}

# =============================================================================
# PARSE FIELDS
# =============================================================================

locals {
  # Convert fields to map - 1Password structure is different from Bitwarden
  # Fields are in sections, we flatten them all
  fields = merge([
    for section in data.onepassword_item.config.section : {
      for field in section.field : field.label => field.value
    }
  ]...)

  # Helper to safely get field value
  get_field = { for k, v in var.field_names : k => lookup(local.fields, v, "") }
}
