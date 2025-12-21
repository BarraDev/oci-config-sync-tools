#!/bin/bash
# 1Password Provider Implementation
# Implements the vault provider interface for 1Password CLI (op)

provider_name() {
    echo "1password"
}

provider_check_installed() {
    command -v op &> /dev/null
}

provider_install_instructions() {
    echo "1Password CLI installation:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install 1password-cli"
    elif [[ -f /etc/debian_version ]]; then
        echo "  # Add 1Password apt repository first, then:"
        echo "  sudo apt install 1password-cli"
        echo "  # See: https://developer.1password.com/docs/cli/get-started/"
    else
        echo "  # See: https://developer.1password.com/docs/cli/get-started/"
    fi
}

provider_login() {
    # Check if already signed in and session is valid
    if op account list &>/dev/null && op vault list &>/dev/null; then
        log_info "1Password: Session active"
        return 0
    fi

    log_step "1Password: Signing in..."

    # Modern 1Password CLI (v2+) uses different auth methods:
    # 1. Desktop app integration (preferred): op signin
    # 2. Service account: OP_SERVICE_ACCOUNT_TOKEN env var
    # 3. Manual: op signin --account <account>

    if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
        # Service account token is set, no interactive login needed
        log_info "1Password: Using service account token"
        return 0
    fi

    # Try interactive signin (will use desktop app if available)
    if ! eval $(op signin 2>/dev/null); then
        log_error "1Password: Failed to sign in"
        log_info "Tips:"
        log_info "  - Ensure 1Password desktop app is running and unlocked"
        log_info "  - Or set OP_SERVICE_ACCOUNT_TOKEN for non-interactive use"
        log_info "  - Or run: op signin --account <your-account>"
        return 1
    fi

    return 0
}

provider_list_items() {
    # Search for items with "OCI Terraform -" in the title
    # Don't restrict by category - user may use different item types
    op item list --format json 2>/dev/null | \
        jq -r '.[] | select(.title | startswith("OCI Terraform -")) | .title' 2>/dev/null || echo ""
}

provider_get_item() {
    local item_name="$1"
    op item get "$item_name" --format json 2>/dev/null
}

provider_get_field() {
    local item_json="$1"
    local field_name="$2"

    # 1Password stores fields in a different structure
    # Fields are in .fields[] with .label and .value
    echo "$item_json" | jq -r ".fields[]? | select(.label == \"$field_name\") | .value // empty" 2>/dev/null
}

provider_get_item_id() {
    local item_json="$1"
    echo "$item_json" | jq -r '.id'
}

# NOTE: Attachments are no longer used. PEM keys are stored as text fields.
provider_get_attachment() {
    log_warn "Attachments deprecated - PEM keys are now stored as text fields"
    return 1
}

provider_create_item() {
    local item_name="$1"
    local fields_json="$2"

    # Build the op item create command with fields
    local cmd="op item create --category 'Secure Note' --title '$item_name'"

    # Parse fields JSON and add each field
    local field_count
    field_count=$(echo "$fields_json" | jq 'length')

    for ((i=0; i<field_count; i++)); do
        local label value field_type
        label=$(echo "$fields_json" | jq -r ".[$i].label")
        value=$(echo "$fields_json" | jq -r ".[$i].value")
        field_type=$(echo "$fields_json" | jq -r ".[$i].type // \"text\"")

        if [[ -n "$value" ]]; then
            if [[ "$field_type" == "concealed" ]]; then
                cmd+=" --field '${label}[password]=${value}'"
            else
                cmd+=" --field '${label}=${value}'"
            fi
        fi
    done

    # Execute and return result
    eval "$cmd" --format json 2>/dev/null
}

provider_update_item() {
    local item_id="$1"
    local item_name="$2"
    local fields_json="$3"

    # Build the op item edit command
    local cmd="op item edit '$item_id' --title '$item_name'"

    # Parse fields JSON and add each field
    local field_count
    field_count=$(echo "$fields_json" | jq 'length')

    for ((i=0; i<field_count; i++)); do
        local label value field_type
        label=$(echo "$fields_json" | jq -r ".[$i].label")
        value=$(echo "$fields_json" | jq -r ".[$i].value")
        field_type=$(echo "$fields_json" | jq -r ".[$i].type // \"text\"")

        if [[ -n "$value" ]]; then
            if [[ "$field_type" == "concealed" ]]; then
                cmd+=" '${label}[password]=${value}'"
            else
                cmd+=" '${label}=${value}'"
            fi
        fi
    done

    # Execute and return result
    eval "$cmd" --format json 2>/dev/null
}

# NOTE: Attachments are no longer used. PEM keys are stored as text fields.
provider_add_attachment() {
    log_warn "Attachments deprecated - PEM keys are now stored as text fields"
    return 0
}

provider_sync() {
    # 1Password CLI syncs automatically, no manual sync needed
    return 0
}

# ============================================================================
# 1PASSWORD-SPECIFIC FIELD BUILDING
# ============================================================================

# Build fields JSON array for 1Password
# 1Password uses: { label: "field_name", value: "value", type: "text"|"concealed" }
provider_build_fields_json() {
    local fields="[]"

    # Helper to add a field
    _add_op_field() {
        local label="$1"
        local value="$2"
        local concealed="${3:-false}"

        local field_type="text"
        [[ "$concealed" == "true" ]] && field_type="concealed"

        if [[ -n "$value" ]]; then
            fields=$(echo "$fields" | jq \
                --arg label "$label" \
                --arg value "$value" \
                --arg type "$field_type" \
                '. + [{label: $label, value: $value, type: $type}]')
        fi
    }

    # OCI Authentication
    _add_op_field "oci_tenancy_ocid" "${CONFIG_OCI_TENANCY_OCID:-}"
    _add_op_field "oci_user_ocid" "${CONFIG_OCI_USER_OCID:-}"
    _add_op_field "oci_fingerprint" "${CONFIG_OCI_FINGERPRINT:-}"
    _add_op_field "oci_region" "${CONFIG_OCI_REGION:-}"
    _add_op_field "oci_namespace" "${CONFIG_OCI_NAMESPACE:-}"
    _add_op_field "oci_compartment_id" "${CONFIG_OCI_COMPARTMENT_ID:-}"

    # OCI Infrastructure
    _add_op_field "oci_public_subnet_id" "${CONFIG_OCI_PUBLIC_SUBNET_ID:-}"
    _add_op_field "oci_vault_id" "${CONFIG_OCI_VAULT_ID:-}"

    # Cluster Config
    _add_op_field "domain" "${CONFIG_DOMAIN:-}"
    _add_op_field "github_org" "${CONFIG_GITHUB_ORG:-}"
    _add_op_field "github_repo" "${CONFIG_GITHUB_REPO:-}"
    _add_op_field "github_email" "${CONFIG_GITHUB_EMAIL:-}"
    _add_op_field "admin_username" "${CONFIG_ADMIN_USERNAME:-}"
    _add_op_field "ssh_public_key" "${CONFIG_SSH_PUBLIC_KEY:-}"

    # GitHub FluxCD (secrets are concealed)
    _add_op_field "gh_token" "${CONFIG_GH_TOKEN:-}" true
    _add_op_field "github_app_id" "${CONFIG_GITHUB_APP_ID:-}"
    _add_op_field "github_app_installation_id" "${CONFIG_GITHUB_APP_INSTALLATION_ID:-}"

    # GitHub OAuth Dex
    _add_op_field "github_dex_client_id" "${CONFIG_GITHUB_DEX_CLIENT_ID:-}"
    _add_op_field "github_dex_client_secret" "${CONFIG_GITHUB_DEX_CLIENT_SECRET:-}" true

    # GitHub OAuth Teleport
    _add_op_field "teleport_github_org" "${CONFIG_TELEPORT_GITHUB_ORG:-}"
    _add_op_field "teleport_github_client_id" "${CONFIG_TELEPORT_GITHUB_CLIENT_ID:-}"
    _add_op_field "teleport_github_client_secret" "${CONFIG_TELEPORT_GITHUB_CLIENT_SECRET:-}" true

    # Cloudflare
    _add_op_field "cloudflare_api_token" "${CONFIG_CLOUDFLARE_API_TOKEN:-}" true

    # Telegram
    _add_op_field "telegram_bot_token" "${CONFIG_TELEGRAM_BOT_TOKEN:-}" true
    _add_op_field "telegram_chat_id" "${CONFIG_TELEGRAM_CHAT_ID:-}" true

    # Kubernetes
    _add_op_field "kubernetes_version" "${CONFIG_KUBERNETES_VERSION:-}"
    _add_op_field "kubernetes_arm_node_pool_enabled" "${CONFIG_KUBERNETES_ARM_ENABLED:-}"
    _add_op_field "kubernetes_arm_node_pool_size" "${CONFIG_KUBERNETES_ARM_SIZE:-}"
    _add_op_field "kubernetes_x86_node_pool_enabled" "${CONFIG_KUBERNETES_X86_ENABLED:-}"
    _add_op_field "kubernetes_x86_node_pool_size" "${CONFIG_KUBERNETES_X86_SIZE:-}"
    _add_op_field "kubernetes_x86_ocpus" "${CONFIG_KUBERNETES_X86_OCPUS:-}"
    _add_op_field "kubernetes_x86_memory_gb" "${CONFIG_KUBERNETES_X86_MEMORY:-}"
    _add_op_field "kubernetes_x86_shape" "${CONFIG_KUBERNETES_X86_SHAPE:-}"

    # Apps Repository (optional)
    _add_op_field "apps_enabled" "${CONFIG_APPS_ENABLED:-}"
    _add_op_field "apps_github_org" "${CONFIG_APPS_GITHUB_ORG:-}"
    _add_op_field "apps_github_repo" "${CONFIG_APPS_GITHUB_REPO:-}"

    # GitHub ARC
    _add_op_field "github_arc_app_id" "${CONFIG_GITHUB_ARC_APP_ID:-}"
    _add_op_field "github_arc_private_key" "${CONFIG_GITHUB_ARC_PRIVATE_KEY:-}" true
    _add_op_field "github_arc_shingonoide_installation_id" "${CONFIG_GITHUB_ARC_SHINGONOIDE_INSTALL_ID:-}"
    _add_op_field "github_arc_dictmagic_installation_id" "${CONFIG_GITHUB_ARC_DICTMAGIC_INSTALL_ID:-}"

    # PEM Keys (stored as text fields instead of attachments)
    _add_op_field "oci_private_key" "${CONFIG_OCI_PRIVATE_KEY:-}" true
    _add_op_field "github_app_pem" "${CONFIG_GITHUB_APP_PEM:-}" true

    echo "$fields"
}
