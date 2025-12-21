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

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_verbose() { $VERBOSE && echo -e "${CYAN}[DEBUG]${NC} $1" || true; }
log_dry_run() { echo -e "${YELLOW}[DRY-RUN]${NC} Would: $1"; }

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

# Load the field names mapping
load_field_names() {
    local loader_root="$(get_loader_root)"
    local config_file="$loader_root/config/field-names.json"

    if [[ ! -f "$config_file" ]]; then
        log_error "Field names config not found: $config_file"
        return 1
    fi

    cat "$config_file"
}

# Get Bitwarden field name for a Terraform variable
get_bitwarden_field_name() {
    local tf_var="$1"
    local field_names="$2"

    echo "$field_names" | jq -r --arg var "$tf_var" '.[$var] // $var'
}

# Get Terraform variable name for a Bitwarden field
get_terraform_var_name() {
    local bw_field="$1"
    local field_names="$2"

    # Reverse lookup - find key by value
    echo "$field_names" | jq -r --arg field "$bw_field" 'to_entries | .[] | select(.value == $field) | .key // $field'
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
write_tfvar() {
    local file="$1"
    local var_name="$2"
    local value="$3"

    # Escape special characters in value
    local escaped_value

    # Check if value is multiline (contains newlines)
    if [[ "$value" == *$'\n'* ]]; then
        # Use heredoc syntax for multiline values
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
    elif [[ "$value" == "{"* || "$value" == "["* ]]; then
        # Map or list values - write as-is (should be valid HCL)
        echo "$var_name = $value" >> "$file"
    else
        # String values with quotes, escape internal quotes
        escaped_value="${value//\\/\\\\}"
        escaped_value="${escaped_value//\"/\\\"}"
        echo "$var_name = \"$escaped_value\"" >> "$file"
    fi
}
