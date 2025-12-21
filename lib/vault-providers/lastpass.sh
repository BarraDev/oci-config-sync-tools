#!/bin/bash
# LastPass Provider Implementation
# Implements the vault provider interface for LastPass CLI (lpass)

provider_name() {
    echo "lastpass"
}

provider_check_installed() {
    command -v lpass &> /dev/null
}

provider_install_instructions() {
    echo "LastPass CLI installation:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install lastpass-cli"
    elif [[ -f /etc/debian_version ]]; then
        echo "  sudo apt install lastpass-cli"
    elif [[ -f /etc/redhat-release ]]; then
        echo "  sudo dnf install lastpass-cli"
    else
        echo "  # Build from source: https://github.com/lastpass/lastpass-cli"
    fi
}

provider_login() {
    # Check if already logged in
    if lpass status &>/dev/null; then
        local status
        status=$(lpass status 2>/dev/null)
        if [[ "$status" == *"Logged in as"* ]]; then
            log_info "LastPass: Session active"
            return 0
        fi
    fi

    log_step "LastPass: Logging in..."
    # lpass login will prompt for email and master password
    # The email can be passed as argument or prompted
    if [[ -n "${LASTPASS_EMAIL:-}" ]]; then
        lpass login "$LASTPASS_EMAIL"
    else
        echo "Enter your LastPass email:"
        read -r email
        lpass login "$email"
    fi
    return $?
}

provider_list_items() {
    # Search for items with "OCI Terraform -" in the name
    # LastPass uses folder/name format
    lpass ls 2>/dev/null | grep -i "OCI Terraform -" | sed 's/ \[id:.*$//' | sed 's/^.*\///' || echo ""
}

provider_get_item() {
    local item_name="$1"
    # LastPass doesn't have native JSON output, we need to build it
    # Get all fields using --format
    local item_data
    item_data=$(lpass show "$item_name" --json 2>/dev/null)

    if [[ -z "$item_data" || "$item_data" == "[]" ]]; then
        # Try with full path search
        item_data=$(lpass show --json "$(lpass ls 2>/dev/null | grep -i "$item_name" | head -1 | sed 's/ \[id:.*$//')" 2>/dev/null)
    fi

    echo "$item_data"
}

provider_get_field() {
    local item_json="$1"
    local field_name="$2"

    # LastPass JSON structure has fields in a different format
    # Try to get from note fields first (custom fields)
    local value

    # Check if it's a standard field
    value=$(echo "$item_json" | jq -r ".[0].${field_name} // empty" 2>/dev/null)

    if [[ -z "$value" ]]; then
        # Check in note field (LastPass stores custom fields in notes with format: field_name: value)
        local note
        note=$(echo "$item_json" | jq -r '.[0].note // empty' 2>/dev/null)
        if [[ -n "$note" ]]; then
            # Parse the note for field_name: value format
            value=$(echo "$note" | grep -E "^${field_name}:" | sed "s/^${field_name}:[[:space:]]*//" | head -1)

            # Handle multiline values (like PEM keys)
            if [[ -z "$value" ]]; then
                # Try to extract multiline value (field followed by content until next field or EOF)
                value=$(echo "$note" | awk -v field="$field_name" '
                    BEGIN { found=0; value="" }
                    $0 ~ "^" field ":" {
                        found=1
                        sub("^" field ":[[:space:]]*", "")
                        value = $0
                        next
                    }
                    found && /^[a-zA-Z_]+:/ { found=0 }
                    found { value = value "\n" $0 }
                    END { print value }
                ')
            fi
        fi
    fi

    echo "$value"
}

provider_get_item_id() {
    local item_json="$1"
    echo "$item_json" | jq -r '.[0].id // empty'
}

# NOTE: Attachments are no longer used. PEM keys are stored as text fields in notes.
provider_get_attachment() {
    log_warn "Attachments deprecated - PEM keys are stored in notes as text fields"
    return 1
}

provider_create_item() {
    local item_name="$1"
    local fields_json="$2"

    # Build the note content with all fields
    local note_content
    note_content=$(_build_note_from_fields "$fields_json")

    # Create a secure note in LastPass
    # Using printf to handle the note content properly
    printf "Name: %s\nNoteType: Secure Note\nNotes: %s\n" "$item_name" "$note_content" | \
        lpass add --sync=now --non-interactive "$item_name"

    # Return the created item
    provider_get_item "$item_name"
}

provider_update_item() {
    local item_id="$1"
    local item_name="$2"
    local new_fields_json="$3"

    # Get existing item to merge fields
    local existing_item
    existing_item=$(lpass show --json "$item_id" 2>/dev/null)

    # Extract existing note content
    local existing_note
    existing_note=$(echo "$existing_item" | jq -r '.[0].note // ""' 2>/dev/null)

    # Parse existing fields from note
    local existing_fields
    existing_fields=$(_parse_note_to_fields "$existing_note")

    # Merge fields (new overrides existing)
    local merged_fields
    merged_fields=$(_merge_fields "$existing_fields" "$new_fields_json")

    # Build updated note content
    local note_content
    note_content=$(_build_note_from_fields "$merged_fields")

    # Update the item
    printf "Name: %s\nNoteType: Secure Note\nNotes: %s\n" "$item_name" "$note_content" | \
        lpass edit --sync=now --non-interactive "$item_id"

    # Return the updated item
    provider_get_item "$item_name"
}

# NOTE: Attachments are no longer used. PEM keys are stored as text fields.
provider_add_attachment() {
    log_warn "Attachments deprecated - PEM keys are stored in notes as text fields"
    return 0
}

provider_sync() {
    lpass sync > /dev/null 2>&1
}

# ============================================================================
# LASTPASS-SPECIFIC HELPER FUNCTIONS
# ============================================================================

# Build note content from fields JSON
# LastPass stores custom fields in the Notes section with format:
# field_name: value
# (multiline values are stored as-is after the field name)
_build_note_from_fields() {
    local fields_json="$1"
    local note=""

    local field_count
    field_count=$(echo "$fields_json" | jq 'length')

    for ((i=0; i<field_count; i++)); do
        local name value
        name=$(echo "$fields_json" | jq -r ".[$i].name // .[$i].label")
        value=$(echo "$fields_json" | jq -r ".[$i].value")

        if [[ -n "$name" && -n "$value" && "$value" != "null" ]]; then
            # For multiline values, just append the content
            if [[ "$value" == *$'\n'* ]]; then
                note+="${name}:"$'\n'"${value}"$'\n'$'\n'
            else
                note+="${name}: ${value}"$'\n'
            fi
        fi
    done

    echo "$note"
}

# Parse note content back to fields JSON
_parse_note_to_fields() {
    local note="$1"
    local fields="[]"

    # Parse simple key: value pairs and multiline values
    local current_field=""
    local current_value=""
    local in_multiline=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*):(.*)$ ]]; then
            # Save previous field if any
            if [[ -n "$current_field" ]]; then
                fields=$(echo "$fields" | jq \
                    --arg name "$current_field" \
                    --arg value "$current_value" \
                    '. + [{name: $name, value: $value, type: 0}]')
            fi

            current_field="${BASH_REMATCH[1]}"
            current_value="${BASH_REMATCH[2]}"
            current_value="${current_value# }"  # trim leading space

            # Check if this is a multiline value (empty after colon)
            if [[ -z "$current_value" ]]; then
                in_multiline=true
            else
                in_multiline=false
            fi
        elif $in_multiline && [[ -n "$line" ]]; then
            # Append to multiline value
            if [[ -n "$current_value" ]]; then
                current_value+=$'\n'"$line"
            else
                current_value="$line"
            fi
        fi
    done <<< "$note"

    # Save last field
    if [[ -n "$current_field" ]]; then
        fields=$(echo "$fields" | jq \
            --arg name "$current_field" \
            --arg value "$current_value" \
            '. + [{name: $name, value: $value, type: 0}]')
    fi

    echo "$fields"
}

# Merge two field arrays (new overrides existing)
_merge_fields() {
    local existing="$1"
    local new="$2"

    echo "$existing" | jq --argjson new "$new" '
        # Get existing as object keyed by name
        (. | map({(.name): .}) | add // {}) as $existing_obj |
        # Get new as object keyed by name (handle both .name and .label)
        ($new | map({(.name // .label): .}) | add // {}) as $new_obj |
        # Merge: existing + new (new overrides)
        ($existing_obj + $new_obj) | to_entries | map(.value)
    '
}

# ============================================================================
# LASTPASS-SPECIFIC FIELD BUILDING
# ============================================================================

# Build fields JSON array for LastPass
# Uses same structure as Bitwarden: { name: "field_name", value: "value", type: 0|1 }
provider_build_fields_json() {
    local fields="[]"

    # Helper to add a field
    _add_lp_field() {
        local name="$1"
        local value="$2"
        local hidden="${3:-0}"  # 0 = text, 1 = hidden (for reference, LastPass doesn't differentiate in notes)

        if [[ -n "$value" ]]; then
            fields=$(echo "$fields" | jq \
                --arg name "$name" \
                --arg value "$value" \
                --argjson type "$hidden" \
                '. + [{name: $name, value: $value, type: $type}]')
        fi
    }

    # OCI Authentication
    _add_lp_field "oci_tenancy_ocid" "${CONFIG_OCI_TENANCY_OCID:-}"
    _add_lp_field "oci_user_ocid" "${CONFIG_OCI_USER_OCID:-}"
    _add_lp_field "oci_fingerprint" "${CONFIG_OCI_FINGERPRINT:-}"
    _add_lp_field "oci_region" "${CONFIG_OCI_REGION:-}"
    _add_lp_field "oci_namespace" "${CONFIG_OCI_NAMESPACE:-}"
    _add_lp_field "oci_compartment_id" "${CONFIG_OCI_COMPARTMENT_ID:-}"

    # OCI Infrastructure
    _add_lp_field "oci_public_subnet_id" "${CONFIG_OCI_PUBLIC_SUBNET_ID:-}"
    _add_lp_field "oci_vault_id" "${CONFIG_OCI_VAULT_ID:-}"

    # Cluster Config
    _add_lp_field "domain" "${CONFIG_DOMAIN:-}"
    _add_lp_field "github_org" "${CONFIG_GITHUB_ORG:-}"
    _add_lp_field "github_repo" "${CONFIG_GITHUB_REPO:-}"
    _add_lp_field "github_email" "${CONFIG_GITHUB_EMAIL:-}"
    _add_lp_field "admin_username" "${CONFIG_ADMIN_USERNAME:-}"
    _add_lp_field "ssh_public_key" "${CONFIG_SSH_PUBLIC_KEY:-}"

    # GitHub FluxCD (secrets)
    _add_lp_field "gh_token" "${CONFIG_GH_TOKEN:-}" 1
    _add_lp_field "github_app_id" "${CONFIG_GITHUB_APP_ID:-}"
    _add_lp_field "github_app_installation_id" "${CONFIG_GITHUB_APP_INSTALLATION_ID:-}"

    # GitHub OAuth Dex
    _add_lp_field "github_dex_client_id" "${CONFIG_GITHUB_DEX_CLIENT_ID:-}"
    _add_lp_field "github_dex_client_secret" "${CONFIG_GITHUB_DEX_CLIENT_SECRET:-}" 1

    # GitHub OAuth Teleport
    _add_lp_field "teleport_github_org" "${CONFIG_TELEPORT_GITHUB_ORG:-}"
    _add_lp_field "teleport_github_client_id" "${CONFIG_TELEPORT_GITHUB_CLIENT_ID:-}"
    _add_lp_field "teleport_github_client_secret" "${CONFIG_TELEPORT_GITHUB_CLIENT_SECRET:-}" 1

    # Cloudflare
    _add_lp_field "cloudflare_api_token" "${CONFIG_CLOUDFLARE_API_TOKEN:-}" 1

    # Telegram
    _add_lp_field "telegram_bot_token" "${CONFIG_TELEGRAM_BOT_TOKEN:-}" 1
    _add_lp_field "telegram_chat_id" "${CONFIG_TELEGRAM_CHAT_ID:-}" 1

    # Kubernetes
    _add_lp_field "kubernetes_version" "${CONFIG_KUBERNETES_VERSION:-}"
    _add_lp_field "kubernetes_arm_node_pool_enabled" "${CONFIG_KUBERNETES_ARM_ENABLED:-}"
    _add_lp_field "kubernetes_arm_node_pool_size" "${CONFIG_KUBERNETES_ARM_SIZE:-}"
    _add_lp_field "kubernetes_x86_node_pool_enabled" "${CONFIG_KUBERNETES_X86_ENABLED:-}"
    _add_lp_field "kubernetes_x86_node_pool_size" "${CONFIG_KUBERNETES_X86_SIZE:-}"
    _add_lp_field "kubernetes_x86_ocpus" "${CONFIG_KUBERNETES_X86_OCPUS:-}"
    _add_lp_field "kubernetes_x86_memory_gb" "${CONFIG_KUBERNETES_X86_MEMORY:-}"
    _add_lp_field "kubernetes_x86_shape" "${CONFIG_KUBERNETES_X86_SHAPE:-}"

    # Apps Repository (optional)
    _add_lp_field "apps_enabled" "${CONFIG_APPS_ENABLED:-}"
    _add_lp_field "apps_github_org" "${CONFIG_APPS_GITHUB_ORG:-}"
    _add_lp_field "apps_github_repo" "${CONFIG_APPS_GITHUB_REPO:-}"

    # GitHub ARC
    _add_lp_field "github_arc_app_id" "${CONFIG_GITHUB_ARC_APP_ID:-}"
    _add_lp_field "github_arc_private_key" "${CONFIG_GITHUB_ARC_PRIVATE_KEY:-}" 1
    _add_lp_field "github_arc_shingonoide_installation_id" "${CONFIG_GITHUB_ARC_SHINGONOIDE_INSTALL_ID:-}"
    _add_lp_field "github_arc_dictmagic_installation_id" "${CONFIG_GITHUB_ARC_DICTMAGIC_INSTALL_ID:-}"

    # PEM Keys (stored as text fields in notes)
    _add_lp_field "oci_private_key" "${CONFIG_OCI_PRIVATE_KEY:-}" 1
    _add_lp_field "github_app_pem" "${CONFIG_GITHUB_APP_PEM:-}" 1

    echo "$fields"
}
