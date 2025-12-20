# =============================================================================
# EXAMPLE: Using tfvars-loader with Bitwarden
# =============================================================================
#
# Prerequisites:
#   1. Bitwarden account with a Secure Note item containing your config
#   2. Either:
#      - Set BW_EMAIL and BW_PASSWORD environment variables
#      - Or the embedded client will prompt for credentials
#
# Run:
#   export BW_EMAIL="your@email.com"
#   export BW_PASSWORD="your-master-password"
#   terraform init
#   terraform plan
#

terraform {
  required_version = ">= 1.0"
}

# Load configuration from Bitwarden
module "config" {
  source = "../../"

  provider_type = "bitwarden"
  item_name     = "OCI Terraform - example.com"

  # Optional: specify email if not using env var
  # bitwarden_email = "your@email.com"

  # Optional: for self-hosted Bitwarden/Vaultwarden
  # bitwarden_server = "https://vault.example.com"
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

# Example: Configure OCI provider with loaded values
# provider "oci" {
#   region       = module.config.region
#   tenancy_ocid = module.config.tenancy_id
#   user_ocid    = module.config.user_ocid
#   fingerprint  = module.config.fingerprint
#   private_key  = module.config.private_key
# }
