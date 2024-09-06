variable "server_version" {
  description = "The version for the server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server). Changing this forces a new resource to be created."
  default     = "12.0"
  type        = string
}

variable "administrator_login" {
  type = string
}

variable "administrator_login_password" {
  type      = string
  sensitive = true
}

variable "connection_policy" {
  type    = string
  default = "Default"
}

variable "azuread_administrator" {
  description = "Azure AD Administrator Configuration"

  type = object({
    login_username              = optional(string, null)
    object_id                   = optional(string, null)
    tenant_id                   = optional(string)
    azuread_authentication_only = optional(bool)
  })

  default = null
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "outbound_network_restriction_enabled" {
  type    = string
  default = true
}

variable "primary_user_assigned_identity_id" {
  type    = string
  default = null
}

variable "transparent_data_encryption_key_vault_key_id" {
  type    = string
  default = null
}