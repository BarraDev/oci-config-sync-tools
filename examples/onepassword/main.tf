# =============================================================================
# EXAMPLE: Using tfvars-loader with 1Password
# =============================================================================
#
# Prerequisites:
#   1. 1Password account with a service account
#   2. Item in a vault containing your configuration
#
# Run:
#   export OP_SERVICE_ACCOUNT_TOKEN="your-service-account-token"
#   terraform init
#   terraform plan
#

terraform {
  required_version = ">= 1.0"
}

# Load configuration from 1Password
module "config" {
  source = "../../"

  provider_type = "onepassword"
  item_name     = "OCI Terraform - example.com"
  vault_name    = "Infrastructure"

  # Optional: specify token if not using env var
  # onepassword_service_account_token = "your-token"
}

# Example: Use the loaded configuration
output "compartment_id" {
  value = module.config.compartment_id
}

output "region" {
  value = module.config.region
}

output "domain" {
  value = module.config.domain
}
