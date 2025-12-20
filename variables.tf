# =============================================================================
# ITEM CONFIGURATION
# =============================================================================

variable "item_name" {
  description = "Name of the item in Bitwarden (e.g., 'OCI Terraform - example.com')"
  type        = string
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
  description = "Use embedded client (no CLI needed). Requires BW_PASSWORD or BW_CLIENTSECRET env var. Set to false only if using BW_SESSION with external CLI."
  type        = bool
  default     = true
}

variable "bitwarden_master_password" {
  description = "Bitwarden master password (can also use BW_PASSWORD env var). Required if not using session_key."
  type        = string
  default     = ""
  sensitive   = true
}

variable "bitwarden_session_key" {
  description = "Bitwarden session key from `bw unlock --raw` (can also use BW_SESSION env var)"
  type        = string
  default     = ""
  sensitive   = true
}

# =============================================================================
# FIELD MAPPING (customize field names if different from defaults)
# =============================================================================

variable "field_names" {
  description = "Map of output names to field names in the Bitwarden item"
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
