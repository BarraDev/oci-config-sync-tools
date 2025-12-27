#!/bin/bash
# Common functions for tfvars-loader scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global flags
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}

# Logging functions - all go to stderr to not interfere with function return values
log_info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1" >&2; }
log_verbose() { $VERBOSE && echo -e "${CYAN}[DEBUG]${NC} $1" >&2 || true; }
log_dry_run() { echo -e "${YELLOW}[DRY-RUN]${NC} Would: $1" >&2; }

# Check required commands
check_requirements() {
    local missing=()

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        log_info "Install them with:"
        for cmd in "${missing[@]}"; do
            case "$cmd" in
                jq)
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        echo "  brew install jq"
                    else
                        echo "  sudo apt install jq"
                    fi
                    ;;
            esac
        done
        return 1
    fi

    return 0
}

# Get the root directory of tfvars-loader
get_loader_root() {
    local script_path="${BASH_SOURCE[0]}"
    local lib_dir="$(cd "$(dirname "$script_path")" && pwd)"
    echo "$(dirname "$lib_dir")"
}

# List of sensitive variables (should be marked sensitive in tfvars)
SENSITIVE_VARS=(
    "github_token"
    "github_app_pem"
    "github_dex_client_secret"
    "teleport_github_client_secret"
    "telegram_bot_token"
    "telegram_chat_id"
    "cloudflare_api_token"
    "github_arc_private_key"
    "oci_private_key"
)

# Check if a variable is sensitive
is_sensitive_var() {
    local var_name="$1"
    for sensitive in "${SENSITIVE_VARS[@]}"; do
        if [[ "$var_name" == "$sensitive" ]]; then
            return 0
        fi
    done
    return 1
}

# Write a value to tfvars file with proper formatting
# Supports: strings, numbers, booleans, heredocs, maps, lists, and nested structures
write_tfvar() {
    local file="$1"
    local var_name="$2"
    local value="$3"

    # Escape special characters in value
    local escaped_value

    # Check if value is a complex type (map, list, object)
    # These start with { or [ and may be multiline
    if [[ "$value" == "{"* || "$value" == "["* ]]; then
        # Check if it contains newlines (multiline complex type)
        if [[ "$value" == *$'\n'* ]]; then
            # Multiline map/list - write with proper formatting
            echo "$var_name = $value" >> "$file"
            echo "" >> "$file"
        else
            # Single-line map/list
            echo "$var_name = $value" >> "$file"
        fi
    # Check if value is multiline string (contains newlines but not a complex type)
    elif [[ "$value" == *$'\n'* ]]; then
        # Use heredoc syntax for multiline string values
        cat >> "$file" << EOF
$var_name = <<-EOT
$value
EOT

EOF
    elif [[ "$value" == "true" || "$value" == "false" ]]; then
        # Boolean values without quotes
        echo "$var_name = $value" >> "$file"
    elif [[ "$value" =~ ^[0-9]+$ ]]; then
        # Numeric values without quotes
        echo "$var_name = $value" >> "$file"
    else
        # String values with quotes, escape internal quotes
        escaped_value="${value//\\/\\\\}"
        escaped_value="${escaped_value//\"/\\\"}"
        echo "$var_name = \"$escaped_value\"" >> "$file"
    fi
}

# Critical variables that must be verified before cleanup
CRITICAL_VARS=(
    "compartment_id"
    "vault_id"
    "region"
    "domain"
)

# Verify that terraform.tfvars backup exists in vault before allowing cleanup
# Arguments: $1 = terraform directory path
# Returns: 0 if safe to delete (backup verified), 1 if unsafe
verify_vault_backup() {
    local terraform_dir="$1"
    local tfvars_file="$terraform_dir/terraform.tfvars"

    # Check if tfvars file exists
    if [[ ! -f "$tfvars_file" ]]; then
        log_verbose "No terraform.tfvars to verify"
        return 0
    fi

    # Extract domain from tfvars
    local domain
    domain=$(grep -E '^domain\s*=' "$tfvars_file" | sed -E 's/^domain\s*=\s*"(.*)"/\1/' | tr -d ' ')

    if [[ -z "$domain" ]]; then
        log_warn "Could not extract domain from terraform.tfvars"
        log_warn "Unable to verify vault backup - use --force to bypass"
        return 1
    fi

    log_step "Verifying vault backup for domain: $domain"

    # Source vault provider interface
    local loader_root
    loader_root="$(get_loader_root)"
    source "$loader_root/lib/vault-providers/_interface.sh"

    # Detect and load available provider
    local available_providers
    available_providers=$(detect_available_providers)

    if [[ -z "$available_providers" ]]; then
        log_warn "No vault provider (bitwarden/1password/lastpass) installed"
        log_warn "Unable to verify backup - use --force to bypass"
        return 1
    fi

    # Load first available provider
    local provider
    provider=$(echo "$available_providers" | head -1)
    load_provider "$provider"

    log_verbose "Using vault provider: $provider"

    # Login/unlock vault
    if ! provider_login; then
        log_warn "Failed to login to vault"
        log_warn "Unable to verify backup - use --force to bypass"
        return 1
    fi

    # Get vault item
    local item_name="OCI Terraform - $domain"
    local vault_item
    vault_item=$(provider_get_item "$item_name")

    if [[ -z "$vault_item" ]] || [[ "$vault_item" == "null" ]]; then
        log_error "Vault item not found: $item_name"
        log_error "Backup does not exist in vault!"
        log_warn "Run 'oci-config-export $terraform_dir' first"
        return 1
    fi

    log_info "✓ Found vault item: $item_name"

    # Verify critical variables
    log_step "Verifying critical variables..."
    local all_match=true

    for var_name in "${CRITICAL_VARS[@]}"; do
        # Get value from local tfvars
        local local_value
        local_value=$(grep -E "^${var_name}\s*=" "$tfvars_file" | sed -E "s/^${var_name}\s*=\s*\"(.*)\"/\1/" | tr -d ' ')

        if [[ -z "$local_value" ]]; then
            log_verbose "  - $var_name: not in local tfvars (skipping)"
            continue
        fi

        # Get value from vault
        local vault_value
        vault_value=$(provider_get_field "$vault_item" "$var_name")

        if [[ -z "$vault_value" ]]; then
            log_warn "  - $var_name: missing in vault"
            all_match=false
            continue
        fi

        # Compare values
        if [[ "$local_value" == "$vault_value" ]]; then
            log_info "  ✓ $var_name: match"
        else
            log_error "  ✗ $var_name: MISMATCH"
            log_error "    Local:  $local_value"
            log_error "    Vault:  $vault_value"
            all_match=false
        fi
    done

    if $all_match; then
        log_info "✓ All critical variables verified in vault"
        log_info "✓ Safe to remove terraform.tfvars"
        return 0
    else
        log_error "✗ Vault backup verification failed"
        log_warn "Some values don't match or are missing in vault"
        log_warn "Run 'oci-config-export $terraform_dir' to update vault"
        return 1
    fi
}
