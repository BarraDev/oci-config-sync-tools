# =============================================================================
# TERRAFORM OCI TFVARS LOADER
# =============================================================================
#
# This module loads configuration from password managers (Bitwarden/1Password)
# and exposes them as outputs for use in Terraform configurations.
#
# Usage:
#   module "config" {
#     source        = "BarraDev/tfvars-loader/oci"
#     provider_type = "bitwarden"
#     item_name     = "OCI Terraform - example.com"
#   }
#

# -----------------------------------------------------------------------------
# BITWARDEN PROVIDER
# -----------------------------------------------------------------------------

module "bitwarden" {
  source = "./modules/bitwarden"
  count  = var.provider_type == "bitwarden" ? 1 : 0

  item_name       = var.item_name
  email           = var.bitwarden_email
  server          = var.bitwarden_server
  embedded_client = var.bitwarden_embedded_client
  field_names     = var.field_names
}

# -----------------------------------------------------------------------------
# 1PASSWORD PROVIDER
# -----------------------------------------------------------------------------

module "onepassword" {
  source = "./modules/onepassword"
  count  = var.provider_type == "onepassword" ? 1 : 0

  item_name             = var.item_name
  vault_name            = var.vault_name
  service_account_token = var.onepassword_service_account_token
  account               = var.onepassword_account
  field_names           = var.field_names
}

# -----------------------------------------------------------------------------
# UNIFIED OUTPUTS
# -----------------------------------------------------------------------------

locals {
  # Select the appropriate provider outputs
  config = var.provider_type == "bitwarden" ? module.bitwarden[0] : module.onepassword[0]
}
