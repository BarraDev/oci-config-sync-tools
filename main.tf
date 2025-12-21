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
# Authentication options (embedded_client = true, default):
#   Option 1 - API Key (recommended, works with 2FA):
#     - BW_CLIENTID: API client ID from Bitwarden settings
#     - BW_CLIENTSECRET: API client secret
#     - BW_PASSWORD: Master password (still needed to decrypt vault)
#
#   Option 2 - Password only (no 2FA):
#     - BW_EMAIL: Your Bitwarden email
#     - BW_PASSWORD: Your master password
#
# Alternative (embedded_client = false):
#   - Bitwarden CLI installed
#   - BW_SESSION from `bw unlock --raw`
#

# =============================================================================
# BITWARDEN PROVIDER
# =============================================================================

provider "bitwarden" {
  # Authentication depends on embedded_client mode:
  # - embedded_client = true (default): uses API Key or Email+Password
  # - embedded_client = false: uses BW_SESSION (external CLI)
  email  = var.bitwarden_email != "" ? var.bitwarden_email : null
  server = var.bitwarden_server != "" ? var.bitwarden_server : null

  # API Key authentication (works with 2FA enabled)
  client_id     = var.bitwarden_client_id != "" ? var.bitwarden_client_id : null
  client_secret = var.bitwarden_client_secret != "" ? var.bitwarden_client_secret : null

  # Only use master_password with embedded client
  master_password = var.bitwarden_embedded_client ? (
    var.bitwarden_master_password != "" ? var.bitwarden_master_password : null
  ) : null

  # Only use session_key with external CLI (not embedded)
  session_key = !var.bitwarden_embedded_client ? (
    var.bitwarden_session_key != "" ? var.bitwarden_session_key : null
  ) : null

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
