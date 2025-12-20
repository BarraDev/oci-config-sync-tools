# =============================================================================
# TEST: Validar que o módulo carrega dados do Bitwarden corretamente
# =============================================================================
#
# Como testar:
#   1. Faça login no Bitwarden: export BW_SESSION=$(bw unlock --raw)
#   2. terraform init
#   3. terraform plan
#
# Se funcionar, você verá os outputs com seus dados do Bitwarden!
#

terraform {
  required_version = ">= 1.0"

  # Sem backend remoto - só teste local
}

# Carrega configuração do Bitwarden
module "config" {
  source = "../../"

  item_name = "OCI Terraform - barradev.com"
}

# =============================================================================
# OUTPUTS - Mostra os valores carregados (sem sensitive)
# =============================================================================

output "test_compartment_id" {
  description = "Compartment ID carregado do Bitwarden"
  value       = module.config.compartment_id
}

output "test_region" {
  description = "Region carregada do Bitwarden"
  value       = module.config.region
}

output "test_domain" {
  description = "Domain carregado do Bitwarden"
  value       = module.config.domain
}

output "test_github_org" {
  description = "GitHub Org carregada do Bitwarden"
  value       = module.config.github_org
}

output "test_vault_id" {
  description = "OCI Vault ID carregado do Bitwarden"
  value       = module.config.vault_id
}

output "test_github_arc_app_id" {
  description = "GitHub ARC App ID carregado do Bitwarden"
  value       = module.config.github_arc_app_id
}

output "test_apps_enabled" {
  description = "Apps enabled carregado do Bitwarden"
  value       = module.config.apps_enabled
}

output "test_apps_github_repo" {
  description = "Apps repo carregado do Bitwarden"
  value       = module.config.apps_github_repo
}

# Confirmação de sucesso
output "status" {
  description = "Status do teste"
  value       = "✅ Módulo carregou dados do Bitwarden com sucesso!"
}
