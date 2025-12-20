variable "item_name" {
  description = "Name of the item in 1Password"
  type        = string
}

variable "vault_name" {
  description = "Name of the vault containing the item"
  type        = string
}

variable "service_account_token" {
  description = "1Password service account token (can also use OP_SERVICE_ACCOUNT_TOKEN env var)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "account" {
  description = "1Password account URL or ID"
  type        = string
  default     = ""
}

variable "field_names" {
  description = "Map of output names to field names in the item"
  type        = map(string)
}
