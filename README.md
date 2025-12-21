# Terraform tfvars Loader

CLI tools to manage Terraform variables using Bitwarden or 1Password as a secrets store.

## Features

- **Smart Variable Detection**: Automatically parses `_variables.tf` to find required variables
- **Vault Integration**: Supports both Bitwarden and 1Password
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

### Field Name Mapping

Terraform variable names are mapped to Bitwarden field names via `config/field-names.json`:

```json
{
  "compartment_id": "oci_compartment_id",
  "github_token": "gh_token",
  "vault_id": "oci_vault_id"
}
```

This allows vault fields to use different naming conventions than Terraform variables.

### Vault Item Structure

Configuration is stored in a Secure Note named `OCI Terraform - {domain}`:

```
OCI Terraform - example.com
├── oci_compartment_id: ocid1.compartment...
├── oci_region: us-phoenix-1
├── gh_token: ghp_xxxxx (hidden)
├── github_app_pem: -----BEGIN RSA... (hidden)
└── ...
```

## Requirements

- `jq` - JSON processor
- One of:
  - `bw` - Bitwarden CLI
  - `op` - 1Password CLI

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

# Login
op signin
```

## Project Structure

```
terraform-oci-tfvars-loader/
├── bin/
│   ├── tfvars-setup      # Generate tfvars from vault
│   └── tfvars-export     # Export tfvars to vault
├── lib/
│   ├── common.sh         # Shared utilities
│   ├── tfvars-parser.sh  # Parse _variables.tf
│   └── vault-providers/
│       ├── _interface.sh # Provider abstraction
│       ├── bitwarden.sh  # Bitwarden implementation
│       └── onepassword.sh # 1Password implementation
├── config/
│   └── field-names.json  # Variable name mapping
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

# 4. After updating tfvars - sync back to vault
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
