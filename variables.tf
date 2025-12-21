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

variable "bitwarden_client_id" {
  description = "Bitwarden API client ID (can also use BW_CLIENTID env var). Get from Bitwarden Settings → Security → Keys."
  type        = string
  default     = ""
}

variable "bitwarden_client_secret" {
  description = "Bitwarden API client secret (can also use BW_CLIENTSECRET env var)"
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
    # OCI Configuration
    compartment_id = "oci_compartment_id"
    tenancy_id     = "oci_tenancy_ocid"
    region         = "oci_region"
    vault_id       = "oci_vault_id"
    namespace      = "oci_namespace"
    user_ocid      = "oci_user_ocid"
    fingerprint    = "oci_fingerprint"
    private_key    = "oci_private_key"

    # Domain & Basic
    domain         = "domain"
    admin_username = "admin_username"
    ssh_public_key = "ssh_public_key"

    # GitHub Basic
    github_org   = "github_org"
    github_repo  = "github_repo"
    github_email = "github_email"
    github_token = "gh_token"

    # GitHub App (FluxCD)
    github_app_id              = "github_app_id"
    github_app_installation_id = "github_app_installation_id"
    github_app_pem             = "github_app_pem"

    # GitHub ARC
    github_arc_app_id                 = "github_arc_app_id"
    github_arc_private_key            = "github_arc_private_key"
    github_arc_shingonoide_install_id = "github_arc_shingonoide_installation_id"
    github_arc_dictmagic_install_id   = "github_arc_dictmagic_installation_id"

    # GitHub Dex (OAuth)
    github_dex_client_id     = "github_dex_client_id"
    github_dex_client_secret = "github_dex_client_secret"

    # Teleport
    teleport_github_org           = "teleport_github_org"
    teleport_github_client_id     = "teleport_github_client_id"
    teleport_github_client_secret = "teleport_github_client_secret"

    # Telegram
    telegram_bot_token = "telegram_bot_token"
    telegram_chat_id   = "telegram_chat_id"

    # Cloudflare
    cloudflare_api_token = "cloudflare_api_token"

    # Apps Repository
    apps_enabled     = "apps_enabled"
    apps_github_org  = "apps_github_org"
    apps_github_repo = "apps_github_repo"
  }
}
