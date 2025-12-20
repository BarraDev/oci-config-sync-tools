# =============================================================================
# EXAMPLE: Complete OCI Infrastructure with tfvars-loader
# =============================================================================
#
# This example shows how to use tfvars-loader to configure a complete
# OCI infrastructure deployment, similar to oci-free-cloud-k8s.
#

terraform {
  required_version = ">= 1.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
}

# =============================================================================
# LOAD CONFIGURATION FROM PASSWORD MANAGER
# =============================================================================

module "config" {
  source = "../../"

  provider_type = "bitwarden"
  item_name     = "OCI Terraform - example.com"
}

# =============================================================================
# CONFIGURE OCI PROVIDER
# =============================================================================

provider "oci" {
  region       = module.config.region
  tenancy_ocid = module.config.tenancy_id
  user_ocid    = module.config.user_ocid
  fingerprint  = module.config.fingerprint
  private_key  = module.config.private_key
}

# =============================================================================
# EXAMPLE RESOURCES
# =============================================================================

# Create a VCN using loaded configuration
resource "oci_core_vcn" "main" {
  compartment_id = module.config.compartment_id
  display_name   = "k8s-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "k8svcn"
}

# Store a secret in OCI Vault
data "oci_kms_vault" "main" {
  vault_id = module.config.vault_id
}

# Output useful information
output "vcn_id" {
  value = oci_core_vcn.main.id
}

output "vault_name" {
  value = data.oci_kms_vault.main.display_name
}

output "github_org" {
  value = module.config.github_org
}

output "apps_repo" {
  value = module.config.apps_enabled ? module.config.apps_github_repo : "disabled"
}
