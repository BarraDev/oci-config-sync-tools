# =============================================================================
# OCI CONFIGURATION
# =============================================================================

output "compartment_id" {
  description = "OCI Compartment OCID"
  value       = local.get_field["compartment_id"]
}

output "tenancy_id" {
  description = "OCI Tenancy OCID"
  value       = local.get_field["tenancy_id"]
}

output "region" {
  description = "OCI Region"
  value       = local.get_field["region"]
}

output "vault_id" {
  description = "OCI Vault OCID"
  value       = local.get_field["vault_id"]
}

output "namespace" {
  description = "OCI Object Storage namespace"
  value       = local.get_field["namespace"]
}

output "user_ocid" {
  description = "OCI User OCID"
  value       = local.get_field["user_ocid"]
}

output "fingerprint" {
  description = "OCI API Key fingerprint"
  value       = local.get_field["fingerprint"]
}

output "private_key" {
  description = "OCI API private key"
  value       = local.get_field["private_key"]
  sensitive   = true
}

# =============================================================================
# DOMAIN
# =============================================================================

output "domain" {
  description = "Primary domain"
  value       = local.get_field["domain"]
}

# =============================================================================
# GITHUB CONFIGURATION
# =============================================================================

output "github_org" {
  description = "GitHub organization"
  value       = local.get_field["github_org"]
}

output "github_repo" {
  description = "GitHub repository"
  value       = local.get_field["github_repo"]
}

output "github_email" {
  description = "GitHub email"
  value       = local.get_field["github_email"]
}

output "github_token" {
  description = "GitHub token"
  value       = local.get_field["github_token"]
  sensitive   = true
}

# =============================================================================
# GITHUB APP (FLUXCD)
# =============================================================================

output "github_app_id" {
  description = "GitHub App ID"
  value       = local.get_field["github_app_id"]
}

output "github_app_installation_id" {
  description = "GitHub App Installation ID"
  value       = local.get_field["github_app_installation_id"]
}

output "github_app_pem" {
  description = "GitHub App private key"
  value       = local.get_field["github_app_pem"]
  sensitive   = true
}

# =============================================================================
# GITHUB ARC
# =============================================================================

output "github_arc_app_id" {
  description = "GitHub ARC App ID"
  value       = local.get_field["github_arc_app_id"]
}

output "github_arc_private_key" {
  description = "GitHub ARC private key"
  value       = local.get_field["github_arc_private_key"]
  sensitive   = true
}

output "github_arc_installations" {
  description = "GitHub ARC installation IDs"
  value = {
    shingonoide = local.get_field["github_arc_shingonoide_install_id"]
    dictmagic   = local.get_field["github_arc_dictmagic_install_id"]
  }
}

# =============================================================================
# APPS REPOSITORY
# =============================================================================

output "apps_enabled" {
  description = "Apps repository enabled"
  value       = local.get_field["apps_enabled"] == "true"
}

output "apps_github_org" {
  description = "Apps GitHub org"
  value       = local.get_field["apps_github_org"]
}

output "apps_github_repo" {
  description = "Apps GitHub repo"
  value       = local.get_field["apps_github_repo"]
}

# =============================================================================
# RAW FIELDS
# =============================================================================

output "fields" {
  description = "All fields as a map"
  value       = local.fields
  sensitive   = true
}
