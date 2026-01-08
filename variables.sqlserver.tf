variable "server_version" {
  type        = string
  description = "(Required) The version for the new server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server). Changing this forces a new resource to be created."
  nullable    = false
}

variable "administrator_login" {
  type        = string
  default     = null
  description = "(Optional) The administrator login name for the new server. Required unless `azuread_authentication_only` in the `azuread_administrator` block is `true`. When omitted, Azure will generate a default username which cannot be subsequently changed. Changing this forces a new resource to be created."
}

variable "administrator_login_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "(Optional) The password associated with the `administrator_login` user. Needs to comply with Azure's [Password Policy](https://msdn.microsoft.com/library/ms161959.aspx). Required unless `azuread_authentication_only` in the `azuread_administrator` block is `true`. If not provided, a random password will be generated automatically."
}

variable "administrator_login_password_key_vault_configuration" {
  type = object({
    resource_id = string
    name = optional(string, null)
  })
  default = null
  description = <<DESCRIPTION
  (Optional) An object to configure storing the SQL Server administrator password as a secret in Azure Key Vault (KV).
  If omitted, the password won’t be saved in KV.

  - `resource_id` - (Required) The resource ID of the KV where the secret will be stored. Deployment user needs KV secrets write access.
  - `name` - (Optional) Name of the Key Vault secret. Defaults to '<server-name>-<admin-name>-password' if not specified.
  DESCRIPTION
}

variable "azuread_administrator" {
  type = object({
    azuread_authentication_only = optional(bool)
    login_username              = string
    object_id                   = string
    tenant_id                   = optional(string)
  })
  default     = null
  description = <<-EOT
 - `azuread_authentication_only` - (Optional) Specifies whether only AD Users and administrators (e.g. `azuread_administrator[0].login_username`) can be used to login, or also local database users (e.g. `administrator_login`). When `true`, the `administrator_login` and `administrator_login_password` properties can be omitted.
 - `login_username` - (Required) The login username of the Azure AD Administrator of this SQL Server.
 - `object_id` - (Required) The object id of the Azure AD Administrator of this SQL Server.
 - `tenant_id` - (Optional) The tenant id of the Azure AD Administrator of this SQL Server.
EOT
}

variable "connection_policy" {
  type        = string
  default     = null
  description = "(Optional) The connection policy the server will use. Possible values are `Default`, `Proxy`, and `Redirect`. Defaults to `Default`."
}

variable "express_vulnerability_assessment_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Whether the `Express Vulnerability Assessment` feature is enabled for this server. Defaults to `false`."
}

variable "outbound_network_restriction_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether outbound network traffic is restricted for this server. Defaults to `false`."
}

variable "primary_user_assigned_identity_id" {
  type        = string
  default     = null
  description = "(Optional) Specifies the primary user managed identity id. Required if `type` within the `identity` block is set to either `SystemAssigned, UserAssigned` or `UserAssigned` and should be set at same time as setting `identity_ids`."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Whether public network access is allowed for this server. Defaults to `false`."
}

variable "transparent_data_encryption_key_vault_key_id" {
  type        = string
  default     = null
  description = "(Optional) The fully versioned `Key Vault` `Key` URL (e.g. `'https://<YourVaultName>.vault.azure.net/keys/<YourKeyName>/<YourKeyVersion>`) to be used as the `Customer Managed Key`(CMK/BYOK) for the `Transparent Data Encryption`(TDE) layer."
}
