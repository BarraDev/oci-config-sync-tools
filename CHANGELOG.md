# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Safety verification in oci-config-clean**: Added vault backup verification before removing files
  - Verifies that critical variables (compartment_id, vault_id, region, domain) exist in vault
  - Compares local values with vault values to ensure backup is current
  - New `--force` / `--no-verify-vault` flags to bypass verification when needed
  - Clear error messages with actionable instructions when verification fails
  - Function `verify_vault_backup()` in `lib/common.sh` for reusable validation logic
  - Array `CRITICAL_VARS` in `lib/common.sh` to define which variables must be verified

### Changed
- **oci-config-clean**: Now safe by default - will not remove files unless vault backup is verified
- **oci-config-clean help**: Updated to document new safety features and flags

### Security
- **Prevents accidental data loss**: Users can no longer accidentally delete terraform.tfvars without having a vault backup
- **Validates backup integrity**: Ensures vault backup matches local files before deletion

## [Previous Versions]

### Initial Release
- `oci-config-import`: Import terraform.tfvars and _backend.tf from vault
- `oci-config-export`: Export terraform.tfvars and _backend.tf to vault
- `oci-config-clean`: Remove generated configuration files
- Support for multiple vault providers: Bitwarden, 1Password, LastPass
- Automatic variable detection from _variables.tf
- Domain-based vault item naming: "OCI Terraform - {domain}"
