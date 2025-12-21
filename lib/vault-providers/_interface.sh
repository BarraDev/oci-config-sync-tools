#!/bin/bash
# Vault Provider Interface
# Each provider must implement these functions

# ============================================================================
# PROVIDER INTERFACE - Abstract functions that each provider must implement
# ============================================================================

# Returns the provider name (e.g., "bitwarden", "1password")
# Usage: provider_name
provider_name() {
    echo "undefined"
}

# Check if the provider CLI is installed
# Returns: 0 if installed, 1 if not
# Usage: provider_check_installed
provider_check_installed() {
    return 1
}

# Get installation instructions for this provider
# Usage: provider_install_instructions
provider_install_instructions() {
    echo "No installation instructions available"
}

# Login/unlock the vault
# Returns: 0 on success, 1 on failure
# Usage: provider_login
provider_login() {
    return 1
}

# List items matching the pattern "OCI Terraform - *"
# Returns: newline-separated list of item names
# Usage: provider_list_items
provider_list_items() {
    echo ""
}

# Get a specific item by name
# Returns: JSON representation of the item
# Usage: provider_get_item "item_name"
provider_get_item() {
    echo ""
}

# Get a field value from an item
# Arguments: $1 = item_json, $2 = field_name
# Returns: field value
# Usage: provider_get_field "$item_json" "field_name"
provider_get_field() {
    echo ""
}

# Get the item ID from item JSON
# Arguments: $1 = item_json
# Returns: item ID
# Usage: provider_get_item_id "$item_json"
provider_get_item_id() {
    echo ""
}

# Download an attachment from an item
# Arguments: $1 = item_id, $2 = attachment_name, $3 = output_path
# Returns: 0 on success, 1 on failure
# Usage: provider_get_attachment "item_id" "attachment_name" "/path/to/output"
provider_get_attachment() {
    return 1
}

# Create a new item with fields
# Arguments: $1 = item_name, $2 = fields_json
# Returns: JSON of created item (with id)
# Usage: provider_create_item "item_name" "$fields_json"
provider_create_item() {
    echo ""
}

# Update an existing item
# Arguments: $1 = item_id, $2 = item_name, $3 = fields_json
# Returns: JSON of updated item
# Usage: provider_update_item "item_id" "item_name" "$fields_json"
provider_update_item() {
    echo ""
}

# Add an attachment to an item
# Arguments: $1 = item_id, $2 = file_path, $3 = attachment_name
# Returns: 0 on success, 1 on failure
# Usage: provider_add_attachment "item_id" "/path/to/file" "attachment_name"
provider_add_attachment() {
    return 1
}

# Sync the vault (refresh local cache)
# Usage: provider_sync
provider_sync() {
    return 0
}

# ============================================================================
# PROVIDER DETECTION AND LOADING
# ============================================================================

VAULT_PROVIDERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOADED_PROVIDER=""

# Detect available providers
# Returns: space-separated list of available provider names
detect_available_providers() {
    local available=""

    for provider_file in "$VAULT_PROVIDERS_DIR"/*.sh; do
        [[ "$(basename "$provider_file")" == "_interface.sh" ]] && continue
        [[ ! -f "$provider_file" ]] && continue

        # Source provider temporarily to check if installed
        (
            source "$provider_file"
            if provider_check_installed; then
                echo "$(provider_name)"
            fi
        )
    done
}

# Load a specific provider
# Arguments: $1 = provider_name
# Returns: 0 on success, 1 if provider not found
load_provider() {
    local provider_name="$1"
    local provider_file="$VAULT_PROVIDERS_DIR/${provider_name}.sh"

    if [[ -f "$provider_file" ]]; then
        source "$provider_file"
        LOADED_PROVIDER="$provider_name"
        return 0
    fi

    return 1
}

# Get list of all supported providers (installed or not)
list_supported_providers() {
    for provider_file in "$VAULT_PROVIDERS_DIR"/*.sh; do
        [[ "$(basename "$provider_file")" == "_interface.sh" ]] && continue
        [[ ! -f "$provider_file" ]] && continue

        basename "$provider_file" .sh
    done
}

# Show installation instructions for all providers
show_all_provider_instructions() {
    echo "Supported vault providers:"
    echo ""

    for provider_file in "$VAULT_PROVIDERS_DIR"/*.sh; do
        [[ "$(basename "$provider_file")" == "_interface.sh" ]] && continue
        [[ ! -f "$provider_file" ]] && continue

        (
            source "$provider_file"
            local name=$(provider_name)
            local installed="not installed"
            provider_check_installed && installed="installed"

            echo "  $name ($installed)"
            provider_install_instructions | sed 's/^/    /'
            echo ""
        )
    done
}
