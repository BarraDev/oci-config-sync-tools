# Terraform tfvars Loader

CLI tools to manage Terraform variables using Bitwarden, 1Password, or LastPass as a secrets store.

## Features

- **Smart Variable Detection**: Automatically parses `_variables.tf` to find required variables
- **Vault Integration**: Supports Bitwarden, 1Password, and LastPass
- **Minimal tfvars**: Generates only the variables your project needs
- **Bidirectional Sync**: Export from tfvars to vault, import from vault to tfvars

## Installation

### Option 1: Clone and use directly

```bash
git clone https://github.com/BarraDev/terraform-oci-tfvars-loader.git
./terraform-oci-tfvars-loader/bin/tfvars-setup --help
```

### Option 2: As a Git submodule

```bash
cd your-terraform-project
git submodule add https://github.com/BarraDev/terraform-oci-tfvars-loader.git scripts/tfvars-loader
./scripts/tfvars-loader/bin/tfvars-setup terraform/config
```

### Option 3: Add to PATH (optional)

```bash
export PATH="$PATH:/path/to/terraform-oci-tfvars-loader/bin"
```

## Usage

### Generate tfvars from vault

```bash
# Generate terraform.tfvars for a specific directory
./bin/tfvars-setup terraform/config

# Specify domain explicitly
./bin/tfvars-setup --domain example.com terraform/infra

# Preview what would be generated
./bin/tfvars-setup --dry-run terraform/config

# Include optional variables (those with defaults)
./bin/tfvars-setup --include-optional terraform/config
```

### Export tfvars to vault

```bash
# Export current tfvars to vault
./bin/tfvars-export terraform/config

# Create new vault item (fail if exists)
./bin/tfvars-export --create terraform/config

# Update existing item (fail if not exists)
./bin/tfvars-export --update terraform/config
```

### Cleanup generated tfvars

```bash
# Remove generated tfvars files (contains secrets)
./bin/tfvars-cleanup terraform/config

# Preview what would be removed
./bin/tfvars-cleanup --dry-run terraform/config

# Clean all terraform directories in a project
./bin/tfvars-cleanup --recursive /path/to/project
```

## How It Works

### Smart Variable Detection

The script analyzes your `_variables.tf` file:

```hcl
# Required variable (no default) - will be loaded from vault
variable "compartment_id" {
  type = string
}

# Optional variable (has default) - skipped unless --include-optional
variable "region" {
  type    = string
  default = "us-phoenix-1"
}
```

Only variables without defaults are fetched from the vault, keeping your tfvars minimal.

### Vault Item Structure

Configuration is stored in a Secure Note named `OCI Terraform - {domain}`. Field names must match Terraform variable names exactly:

```
OCI Terraform - example.com
├── compartment_id: ocid1.compartment...
├── region: us-phoenix-1
├── github_token: ghp_xxxxx (hidden)
├── github_app_pem: -----BEGIN RSA... (hidden)
└── ...
```

## Requirements

- `jq` - JSON processor
- One of:
  - `bw` - Bitwarden CLI
  - `op` - 1Password CLI
  - `lpass` - LastPass CLI

## Vault Provider Setup

### Bitwarden

```bash
# Install
brew install bitwarden-cli  # macOS
npm install -g @bitwarden/cli  # Linux/Windows

# Login
bw login
bw unlock
```

### 1Password

```bash
# Install
brew install 1password-cli  # macOS

# Login (uses desktop app integration)
op signin

# Or use service account for CI/CD
export OP_SERVICE_ACCOUNT_TOKEN="your-token"
```

### LastPass

```bash
# Install
brew install lastpass-cli  # macOS
sudo apt install lastpass-cli  # Debian/Ubuntu

# Login
lpass login your@email.com

# Or set email via environment
export LASTPASS_EMAIL="your@email.com"
lpass login
```

> **Note**: LastPass stores custom fields in the Notes section of Secure Notes.
> Free accounts may have CLI access limitations.

## Project Structure

```
terraform-oci-tfvars-loader/
├── bin/
│   ├── tfvars-setup      # Generate tfvars from vault
│   ├── tfvars-export     # Export tfvars to vault
│   └── tfvars-cleanup    # Remove generated tfvars files
├── lib/
│   ├── common.sh         # Shared utilities
│   ├── tfvars-parser.sh  # Parse _variables.tf
│   └── vault-providers/
│       ├── _interface.sh  # Provider abstraction
│       ├── bitwarden.sh   # Bitwarden implementation
│       ├── onepassword.sh # 1Password implementation
│       └── lastpass.sh    # LastPass implementation
└── README.md
```

## Example Workflow

```bash
# 1. Initial setup - create vault item manually or from existing tfvars
./bin/tfvars-export --domain example.com terraform/config

# 2. On a new machine - generate tfvars from vault
./bin/tfvars-setup terraform/config
./bin/tfvars-setup terraform/infra

# 3. Run terraform
cd terraform/config
terraform init
terraform plan
terraform apply

# 4. Cleanup secrets from disk
./bin/tfvars-cleanup terraform/config

# 5. After updating tfvars - sync back to vault
./bin/tfvars-export terraform/config
```

## Migration from v1.x (Terraform Module)

Version 2.0 changed from a Terraform module to CLI tools. The old module-based approach is no longer supported.

**Before (v1.x):**
```hcl
module "config" {
  source = "BarraDev/tfvars-loader/oci"
  item_name = "OCI Terraform - example.com"
}

locals {
  compartment_id = module.config.compartment_id
}
```

**After (v2.x):**
```bash
# Generate tfvars
./bin/tfvars-setup terraform/config

# Use standard variables
variable "compartment_id" { type = string }
```

Benefits:
- No runtime vault dependency
- Terraform works offline after setup
- Standard tfvars workflow
- Easier debugging

## License

MIT
