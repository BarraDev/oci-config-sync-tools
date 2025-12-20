# Terraform OCI TFVars Loader

A Terraform module that loads infrastructure configuration from password managers (Bitwarden, 1Password) and exposes them as outputs for use in your Terraform configurations.

## Features

- **Multi-provider support**: Bitwarden and 1Password
- **No scripts needed**: Replace setup scripts with native Terraform
- **Secure**: Credentials never written to disk
- **Flexible**: Use with any Terraform project

## Usage

### With Bitwarden

```hcl
module "config" {
  source  = "BarraDev/tfvars-loader/oci"
  version = "~> 1.0"

  provider_type = "bitwarden"
  item_name     = "OCI Terraform - example.com"
}

provider "oci" {
  region = module.config.region
}

resource "oci_core_vcn" "example" {
  compartment_id = module.config.compartment_id
  # ...
}
```

### With 1Password

```hcl
module "config" {
  source  = "BarraDev/tfvars-loader/oci"
  version = "~> 1.0"

  provider_type = "onepassword"
  item_name     = "OCI Terraform - example.com"
  vault_name    = "Infrastructure"
}
```

## Providers Configuration

### Bitwarden

The module uses the [maxlaverse/bitwarden](https://registry.terraform.io/providers/maxlaverse/bitwarden/latest) provider.

**Authentication options:**

1. **Email/Password** (interactive):
   ```hcl
   module "config" {
     source        = "BarraDev/tfvars-loader/oci"
     provider_type = "bitwarden"
     item_name     = "OCI Terraform - example.com"
   }
   ```

2. **Environment variables** (CI/CD):
   ```bash
   export BW_EMAIL="your@email.com"
   export BW_PASSWORD="your-master-password"
   ```

### 1Password

The module uses the official [1Password/onepassword](https://registry.terraform.io/providers/1Password/onepassword/latest) provider.

**Authentication:**
```bash
export OP_SERVICE_ACCOUNT_TOKEN="your-service-account-token"
```

## Outputs

| Output | Description |
|--------|-------------|
| `compartment_id` | OCI Compartment OCID |
| `tenancy_id` | OCI Tenancy OCID |
| `region` | OCI Region |
| `vault_id` | OCI Vault OCID (for secrets) |
| `namespace` | OCI Object Storage namespace |
| `github_org` | GitHub organization |
| `github_repo` | GitHub repository |
| `domain` | Primary domain |
| `github_arc_app_id` | GitHub ARC App ID |
| `github_arc_private_key` | GitHub ARC private key (sensitive) |
| `github_arc_installations` | Map of GitHub ARC installation IDs |

## Submodules

- [bitwarden](./modules/bitwarden) - Bitwarden provider implementation
- [onepassword](./modules/onepassword) - 1Password provider implementation

## Examples

- [bitwarden](./examples/bitwarden) - Basic Bitwarden usage
- [onepassword](./examples/onepassword) - Basic 1Password usage
- [complete](./examples/complete) - Full example with OCI resources

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| bitwarden | >= 0.16.0 (if using Bitwarden) |
| onepassword | >= 2.0.0 (if using 1Password) |

## License

MIT
