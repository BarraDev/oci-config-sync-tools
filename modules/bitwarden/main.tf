# =============================================================================
# BITWARDEN PROVIDER CONFIGURATION
# =============================================================================

provider "bitwarden" {
  # Email can be set via BW_EMAIL environment variable
  email  = var.email != "" ? var.email : null
  server = var.server != "" ? var.server : null

  experimental {
    embedded_client = var.embedded_client
  }
}

# =============================================================================
# LOAD ITEM FROM BITWARDEN
# =============================================================================

data "bitwarden_item_secure_note" "config" {
  search = var.item_name
}

# =============================================================================
# PARSE FIELDS
# =============================================================================

locals {
  # Convert fields array to map for easy access
  fields = { for f in data.bitwarden_item_secure_note.config.field : f.name => f.text }

  # Helper function to safely get field value
  get_field = { for k, v in var.field_names : k => lookup(local.fields, v, "") }
}
