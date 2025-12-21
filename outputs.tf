# =============================================================================
# OCI CONFIGURATION OUTPUTS
# =============================================================================

output "compartment_id" {
  description = "OCI Compartment OCID"
  value       = nonsensitive(local.get_field["compartment_id"])
}

output "tenancy_id" {
  description = "OCI Tenancy OCID"
  value       = nonsensitive(local.get_field["tenancy_id"])
}

output "region" {
  description = "OCI Region"
  value       = nonsensitive(local.get_field["region"])
}

output "vault_id" {
  description = "OCI Vault OCID (for secrets management)"
  value       = nonsensitive(local.get_field["vault_id"])
}

output "namespace" {
  description = "OCI Object Storage namespace"
  value       = nonsensitive(local.get_field["namespace"])
}

output "user_ocid" {
  description = "OCI User OCID"
  value       = nonsensitive(local.get_field["user_ocid"])
}

output "fingerprint" {
  description = "OCI API Key fingerprint"
  value       = nonsensitive(local.get_field["fingerprint"])
}

output "private_key" {
  description = "OCI API private key (PEM format)"
  value       = local.get_field["private_key"]
  sensitive   = true
}

# =============================================================================
# DOMAIN CONFIGURATION
# =============================================================================

output "domain" {
  description = "Primary domain"
  value       = nonsensitive(local.get_field["domain"])
}

# =============================================================================
# GITHUB CONFIGURATION
# =============================================================================

output "github_org" {
  description = "GitHub organization"
  value       = nonsensitive(local.get_field["github_org"])
}

output "github_repo" {
  description = "GitHub repository"
  value       = nonsensitive(local.get_field["github_repo"])
}

output "github_email" {
  description = "GitHub email for commits"
  value       = nonsensitive(local.get_field["github_email"])
}

output "github_token" {
  description = "GitHub personal access token"
  value       = local.get_field["github_token"]
  sensitive   = true
}

# =============================================================================
# GITHUB APP (FLUXCD) CONFIGURATION
# =============================================================================

output "github_app_id" {
  description = "GitHub App ID for FluxCD"
  value       = nonsensitive(local.get_field["github_app_id"])
}

output "github_app_installation_id" {
  description = "GitHub App Installation ID"
  value       = nonsensitive(local.get_field["github_app_installation_id"])
}

output "github_app_pem" {
  description = "GitHub App private key (PEM format)"
  value       = local.get_field["github_app_pem"]
  sensitive   = true
}

# =============================================================================
# GITHUB ACTIONS RUNNER CONTROLLER (ARC) CONFIGURATION
# =============================================================================

output "github_arc_app_id" {
  description = "GitHub App ID for Actions Runner Controller"
  value       = nonsensitive(local.get_field["github_arc_app_id"])
}

output "github_arc_private_key" {
  description = "GitHub ARC App private key (PEM format)"
  value       = local.get_field["github_arc_private_key"]
  sensitive   = true
}

output "github_arc_installations" {
  description = "Map of GitHub ARC installation IDs per org/user"
  value = {
    shingonoide = nonsensitive(local.get_field["github_arc_shingonoide_install_id"])
    dictmagic   = nonsensitive(local.get_field["github_arc_dictmagic_install_id"])
  }
}

# =============================================================================
# APPS REPOSITORY CONFIGURATION
# =============================================================================

output "apps_enabled" {
  description = "Whether apps repository is enabled"
  value       = nonsensitive(local.get_field["apps_enabled"]) == "true"
}

output "apps_github_org" {
  description = "GitHub org for apps repository"
  value       = nonsensitive(local.get_field["apps_github_org"])
}

output "apps_github_repo" {
  description = "GitHub repo name for apps"
  value       = nonsensitive(local.get_field["apps_github_repo"])
}

# =============================================================================
# RAW FIELDS (for accessing any field by name)
# =============================================================================

output "fields" {
  description = "All fields from the password manager item as a map"
  value       = local.fields
  sensitive   = true
}
