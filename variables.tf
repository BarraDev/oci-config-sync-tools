# =============================================================================
# PROVIDER SELECTION
# =============================================================================

variable "provider_type" {
  description = "Password manager provider to use: 'bitwarden' or 'onepassword'"
  type        = string
  default     = "bitwarden"

  validation {
    condition     = contains(["bitwarden", "onepassword"], var.provider_type)
    error_message = "provider_type must be 'bitwarden' or 'onepassword'"
  }
}

# =============================================================================
# ITEM CONFIGURATION
# =============================================================================

variable "item_name" {
  description = "Name of the item in the password manager (e.g., 'OCI Terraform - example.com')"
  type        = string
}

variable "vault_name" {
  description = "Vault/folder name (required for 1Password, optional for Bitwarden)"
  type        = string
  default     = ""
}

# =============================================================================
# BITWARDEN CONFIGURATION
# =============================================================================

variable "bitwarden_email" {
  description = "Bitwarden account email (can also use BW_EMAIL env var)"
  type        = string
  default     = ""
}

variable "bitwarden_server" {
  description = "Bitwarden server URL (for self-hosted/Vaultwarden)"
  type        = string
  default     = ""
}

variable "bitwarden_embedded_client" {
  description = "Use embedded client instead of CLI (experimental, no CLI installation needed)"
  type        = bool
  default     = true
}

# =============================================================================
# 1PASSWORD CONFIGURATION
# =============================================================================

variable "onepassword_service_account_token" {
  description = "1Password service account token (can also use OP_SERVICE_ACCOUNT_TOKEN env var)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "onepassword_account" {
  description = "1Password account URL or ID"
  type        = string
  default     = ""
}

# =============================================================================
# FIELD MAPPING (customize field names if different from defaults)
# =============================================================================

variable "field_names" {
  description = "Map of output names to field names in the password manager item"
  type        = map(string)
  default = {
    compartment_id                    = "oci_compartment_id"
    tenancy_id                        = "oci_tenancy_ocid"
    region                            = "oci_region"
    vault_id                          = "oci_vault_id"
    namespace                         = "oci_namespace"
    user_ocid                         = "oci_user_ocid"
    fingerprint                       = "oci_fingerprint"
    private_key                       = "oci_private_key"
    domain                            = "domain"
    github_org                        = "github_org"
    github_repo                       = "github_repo"
    github_email                      = "github_email"
    github_token                      = "gh_token"
    github_app_id                     = "github_app_id"
    github_app_installation_id        = "github_app_installation_id"
    github_app_pem                    = "github_app_pem"
    github_arc_app_id                 = "github_arc_app_id"
    github_arc_private_key            = "github_arc_private_key"
    github_arc_shingonoide_install_id = "github_arc_shingonoide_installation_id"
    github_arc_dictmagic_install_id   = "github_arc_dictmagic_installation_id"
    apps_enabled                      = "apps_enabled"
    apps_github_org                   = "apps_github_org"
    apps_github_repo                  = "apps_github_repo"
  }
}
