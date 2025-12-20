variable "item_name" {
  description = "Name of the secure note item in Bitwarden"
  type        = string
}

variable "email" {
  description = "Bitwarden account email (can also use BW_EMAIL env var)"
  type        = string
  default     = ""
}

variable "server" {
  description = "Bitwarden server URL (for self-hosted/Vaultwarden)"
  type        = string
  default     = ""
}

variable "embedded_client" {
  description = "Use embedded client instead of CLI"
  type        = bool
  default     = true
}

variable "field_names" {
  description = "Map of output names to field names in the item"
  type        = map(string)
}
