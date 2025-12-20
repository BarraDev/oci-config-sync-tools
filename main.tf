# =============================================================================
# TERRAFORM OCI TFVARS LOADER
# =============================================================================
#
# This module loads configuration from Bitwarden password manager
# and exposes them as outputs for use in Terraform configurations.
#
# Usage:
#   module "config" {
#     source        = "app.terraform.io/barradevdigitalservices/tfvars-loader/oci"
#     provider_type = "bitwarden"
#     item_name     = "OCI Terraform - example.com"
#   }
#
# Requirements (embedded_client = true, default):
#   - BW_EMAIL: Your Bitwarden email
#   - BW_PASSWORD: Your master password
#
# Alternative (embedded_client = false):
#   - Bitwarden CLI installed
#   - BW_SESSION from `bw unlock --raw`
#

# =============================================================================
# BITWARDEN PROVIDER
# =============================================================================

provider "bitwarden" {
  # Authentication - uses environment variables by default:
  # - BW_SESSION (session key from `bw unlock --raw`)
  # - BW_PASSWORD (master password, if not using session)
  # - BW_EMAIL (email for the account)
  email           = var.bitwarden_email != "" ? var.bitwarden_email : null
  server          = var.bitwarden_server != "" ? var.bitwarden_server : null
  master_password = var.bitwarden_master_password != "" ? var.bitwarden_master_password : null
  session_key     = var.bitwarden_session_key != "" ? var.bitwarden_session_key : null

  experimental {
    embedded_client = var.bitwarden_embedded_client
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

  # Helper to safely get field value using configurable field names
  get_field = { for k, v in var.field_names : k => lookup(local.fields, v, "") }
}
