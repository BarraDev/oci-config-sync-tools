# =============================================================================
# OCI CONFIGURATION OUTPUTS
# =============================================================================

output "compartment_id" {
  description = "OCI Compartment OCID"
  value       = local.config.compartment_id
}

output "tenancy_id" {
  description = "OCI Tenancy OCID"
  value       = local.config.tenancy_id
}

output "region" {
  description = "OCI Region"
  value       = local.config.region
}

output "vault_id" {
  description = "OCI Vault OCID (for secrets management)"
  value       = local.config.vault_id
}

output "namespace" {
  description = "OCI Object Storage namespace"
  value       = local.config.namespace
}

output "user_ocid" {
  description = "OCI User OCID"
  value       = local.config.user_ocid
}

output "fingerprint" {
  description = "OCI API Key fingerprint"
  value       = local.config.fingerprint
}

output "private_key" {
  description = "OCI API private key (PEM format)"
  value       = local.config.private_key
  sensitive   = true
}

# =============================================================================
# DOMAIN CONFIGURATION
# =============================================================================

output "domain" {
  description = "Primary domain"
  value       = local.config.domain
}

# =============================================================================
# GITHUB CONFIGURATION
# =============================================================================

output "github_org" {
  description = "GitHub organization"
  value       = local.config.github_org
}

output "github_repo" {
  description = "GitHub repository"
  value       = local.config.github_repo
}

output "github_email" {
  description = "GitHub email for commits"
  value       = local.config.github_email
}

output "github_token" {
  description = "GitHub personal access token"
  value       = local.config.github_token
  sensitive   = true
}

# =============================================================================
# GITHUB APP (FLUXCD) CONFIGURATION
# =============================================================================

output "github_app_id" {
  description = "GitHub App ID for FluxCD"
  value       = local.config.github_app_id
}

output "github_app_installation_id" {
  description = "GitHub App Installation ID"
  value       = local.config.github_app_installation_id
}

output "github_app_pem" {
  description = "GitHub App private key (PEM format)"
  value       = local.config.github_app_pem
  sensitive   = true
}

# =============================================================================
# GITHUB ACTIONS RUNNER CONTROLLER (ARC) CONFIGURATION
# =============================================================================

output "github_arc_app_id" {
  description = "GitHub App ID for Actions Runner Controller"
  value       = local.config.github_arc_app_id
}

output "github_arc_private_key" {
  description = "GitHub ARC App private key (PEM format)"
  value       = local.config.github_arc_private_key
  sensitive   = true
}

output "github_arc_installations" {
  description = "Map of GitHub ARC installation IDs per org/user"
  value       = local.config.github_arc_installations
}

# =============================================================================
# APPS REPOSITORY CONFIGURATION
# =============================================================================

output "apps_enabled" {
  description = "Whether apps repository is enabled"
  value       = local.config.apps_enabled
}

output "apps_github_org" {
  description = "GitHub org for apps repository"
  value       = local.config.apps_github_org
}

output "apps_github_repo" {
  description = "GitHub repo name for apps"
  value       = local.config.apps_github_repo
}

# =============================================================================
# RAW FIELDS (for accessing any field by name)
# =============================================================================

output "fields" {
  description = "All fields from the password manager item as a map"
  value       = local.config.fields
  sensitive   = true
}
