variable "name" {
  type        = string
  description = "The name of the database."
  nullable    = false
}

variable "sql_server" {
  type = object({
    resource_id = string
  })
  description = "The resource ID of the SQL Server to create the database on."
  nullable    = false
}

variable "auto_pause_delay_in_minutes" {
  type        = number
  default     = null
  description = "The time in minutes before the database is automatically paused."
}

variable "collation" {
  type        = string
  default     = null
  description = "The collation of the database."
}

variable "create_mode" {
  type        = string
  default     = "Default"
  description = "The mode to create the database."

  validation {
    condition = var.create_mode == null ? true : contains([
      "Copy", "Default", "OnlineSecondary", "PointInTimeRestore", "Recovery", "Restore", "RestoreExternalBackup",
      "RestoreExternalBackupSecondary", "RestoreLongTermRetentionBackup", "Secondary"
    ], var.create_mode)
    error_message = "Invalid value for create_mode. Allowed values are Copy, Default, OnlineSecondary, PointInTimeRestore, Recovery, Restore, RestoreExternalBackup, RestoreExternalBackupSecondary, RestoreLongTermRetentionBackup, or Secondary."
  }
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "elastic_pool_id" {
  type        = string
  default     = null
  description = "The ID of the elastic pool containing the database."
}

variable "geo_backup_enabled" {
  type        = bool
  default     = true
  description = "Whether geo-backup is enabled for the database."
}

variable "import" {
  type = object({
    storage_uri            = string
    storage_key            = string
    storage_key_type       = string
    administrator_login    = string
    administrator_password = string
    authentication_type    = string
    storage_account_id     = string
  })
  default     = null
  description = <<DESCRIPTION
Controls the Import configuration on this resource. The following properties can be specified:

- `storage_uri` - (Required) Specifies the URI of the storage account to import the database from.
- `storage_key` - (Required) Specifies the key of the storage account to import the database from.
- `storage_key_type` - (Required) Specifies the type of the storage key. Possible values are `StorageAccessKey` and `SharedAccessKey`.
- `administrator_login` - (Required) Specifies the login of the administrator.
- `administrator_password` - (Required) Specifies the password of the administrator.
- `authentication_type` - (Required) Specifies the authentication type. Possible values are `SQL` and `Windows`.
- `storage_account_id` - (Required) Specifies the ID of the storage account to import the database from.
DESCRIPTION
}

variable "ledger_enabled" {
  type        = bool
  default     = false
  description = "Whether ledger is enabled for the database."
}

variable "license_type" {
  type        = string
  default     = null
  description = "The license type for the database."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:
  
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "long_term_retention_policy" {
  type = object({
    weekly_retention  = string
    monthly_retention = string
    yearly_retention  = string
    week_of_year      = number
  })
  default     = null
  description = <<DESCRIPTION
Controls the Long Term Retention Policy configuration on this resource. The following properties can be specified:

- `weekly_retention` - (Required) Specifies the weekly retention policy.
- `monthly_retention` - (Required) Specifies the monthly retention policy.
- `yearly_retention` - (Required) Specifies the yearly retention policy.
- `week_of_year` - (Required) Specifies the week of the year to apply the yearly retention policy.
DESCRIPTION
}

variable "maintenance_configuration_name" {
  type        = string
  default     = null
  description = "The name of the maintenance configuration."

  validation {
    condition = var.maintenance_configuration_name == null ? true : contains([
      "SQL_Default",
      "SQL_AustraliaEast_DB_1", "SQL_AustraliaEast_DB_2", "SQL_AustraliaSoutheast_DB_1", "SQL_AustraliaSoutheast_DB_2",
      "SQL_BrazilSoutheast_DB_1", "SQL_BrazilSoutheast_DB_2", "SQL_BrazilSouth_DB_1", "SQL_BrazilSouth_DB_2",
      "SQL_CanadaCentral_DB_1", "SQL_CanadaCentral_DB_2", "SQL_CanadaEast_DB_1", "SQL_CanadaEast_DB_2",
      "SQL_CentralIndia_DB_1", "SQL_CentralIndia_DB_2", "SQL_CentralUS_DB_1", "SQL_CentralUS_DB_2",
      "SQL_EastAsia_DB_1", "SQL_EastAsia_DB_2", "SQL_EastUS_DB_1", "SQL_EastUS_DB_2", "SQL_EastUS2_DB_1", "SQL_EastUS2_DB_2",
      "SQL_FranceCentral_DB_1", "SQL_FranceCentral_DB_2", "SQL_FranceSouth_DB_1", "SQL_FranceSouth_DB_2",
      "SQL_GermanyWestCentral_DB_1", "SQL_GermanyWestCentral_DB_2",
      "SQL_JapanEast_DB_1", "SQL_JapanEast_DB_2", "SQL_JapanWest_DB_1", "SQL_JapanWest_DB_2",
      "SQL_NorthCentralUS_DB_1", "SQL_NorthCentralUS_DB_2", "SQL_NorthEurope_DB_1", "SQL_NorthEurope_DB_2",
      "SQL_SoutheastAsia_DB_1", "SQL_SoutheastAsia_DB_2", "SQL_SouthCentralUS_DB_1", "SQL_SouthCentralUS_DB_2", "SQL_SouthIndia_DB_1", "SQL_SouthIndia_DB_2",
      "SQL_SwitzerlandNorth_DB_1", "SQL_SwitzerlandNorth_DB_2",
      "SQL_UAENorth_DB_1", "SQL_UAENorth_DB_2", "SQL_UKSouth_DB_1", "SQL_UKSouth_DB_2", "SQL_UKWest_DB_1", "SQL_UKWest_DB_2",
      "SQL_WestCentralUS_DB_1", "SQL_WestCentralUS_DB_2", "SQL_WestEurope_DB_1", "SQL_WestEurope_DB_2",
      "SQL_WestUS2_DB_1", "SQL_WestUS2_DB_2", "SQL_WestUS_DB_1", "SQL_WestUS_DB_2"
    ], var.maintenance_configuration_name)
    error_message = "Invalid value for maintenance_configuration_name."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:
  
  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "max_size_gb" {
  type        = number
  default     = null
  description = "The maximum size of the database in gigabytes."
}

variable "min_capacity" {
  type        = number
  default     = null
  description = "The minimum capacity of the database."
}

variable "read_replica_count" {
  type        = number
  default     = null
  description = "The number of read replicas for the database."
}

variable "read_scale" {
  type        = bool
  default     = null
  description = "Whether read scale is enabled for the database."
}

variable "recover_database_id" {
  type        = string
  default     = null
  description = "The ID of the database to recover."
}

variable "restore_dropped_database_id" {
  type        = string
  default     = null
  description = "The ID of the dropped database to restore."
}

variable "restore_point_in_time" {
  type        = string
  default     = null
  description = "The point in time to restore the database to."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  nullable    = false
}

variable "sample_name" {
  type        = string
  default     = null
  description = "The name of the sample database."
}

variable "short_term_retention_policy" {
  type = object({
    retention_days           = number
    backup_interval_in_hours = number
  })
  default = {
    retention_days           = 35
    backup_interval_in_hours = 12
  }
  description = <<DESCRIPTION
Controls the Short Term Retention Policy configuration on this resource. The following properties can be specified:

- `retention_days` - (Required) Specifies the number of days to keep in the Short Term Retention audit logs.
- `backup_interval_in_hours` - (Required) Specifies the interval in hours to keep in the Short Term Retention audit logs.
DESCRIPTION
}

variable "sku_name" {
  type        = string
  default     = "P2"
  description = "The SKU name for the database."

  validation {
    condition = var.sku_name == null || contains([
      "BC_DC_10", "BC_DC_12", "BC_DC_14", "BC_DC_16", "BC_DC_18", "BC_DC_2", "BC_DC_20", "BC_DC_32",
      "BC_DC_4", "BC_DC_40", "BC_DC_6", "BC_DC_8","BC_Gen5_10", "BC_Gen5_12", "BC_Gen5_128",
      "BC_Gen5_14", "BC_Gen5_16", "BC_Gen5_18", "BC_Gen5_2", "BC_Gen5_20", "BC_Gen5_24", "BC_Gen5_32",
      "BC_Gen5_4", "BC_Gen5_40", "BC_Gen5_6", "BC_Gen5_8", "BC_Gen5_80", "Basic", "DS100", "DS1000",
      "DS1200", "DS1500", "DS200", "DS2000", "DS300", "DS400", "DS500", "DS600", "DW10000c", "DW1000c",
      "DW100c", "DW15000c", "DW1500c", "DW2000c", "DW200c", "DW2500c", "DW30000c", "DW3000c", "DW300c",
      "DW400c", "DW5000c", "DW500c", "DW6000c", "DW7500c", "Free", "GP_DC_10", "GP_DC_12", "GP_DC_14",
      "GP_DC_16", "GP_DC_18", "GP_DC_2", "GP_DC_20", "GP_DC_32", "GP_DC_4", "GP_DC_40", "GP_DC_6", 
      "GP_DC_8", "GP_Fsv2_10", "GP_Fsv2_12", "GP_Fsv2_14", "GP_Fsv2_16", "GP_Fsv2_18", "GP_Fsv2_20",
      "GP_Fsv2_24", "GP_Fsv2_32", "GP_Fsv2_36", "GP_Fsv2_72", "GP_Fsv2_8", "GP_Gen5_10", "GP_Gen5_12",
      "GP_Gen5_128", "GP_Gen5_14", "GP_Gen5_16", "GP_Gen5_18", "GP_Gen5_2", "GP_Gen5_20", "GP_Gen5_24",
      "GP_Gen5_32", "GP_Gen5_4", "GP_Gen5_40", "GP_Gen5_6", "GP_Gen5_8", "GP_Gen5_80", "GP_SYSTEM_2",
      "GP_SYSTEM_4", "GP_SYSTEM_8", "GP_S_Gen5_1", "GP_S_Gen5_10", "GP_S_Gen5_12", "GP_S_Gen5_14",
      "GP_S_Gen5_16", "GP_S_Gen5_18", "GP_S_Gen5_2", "GP_S_Gen5_20", "GP_S_Gen5_24", "GP_S_Gen5_32",
      "GP_S_Gen5_4", "GP_S_Gen5_40", "GP_S_Gen5_6", "GP_S_Gen5_8", "GP_S_Gen5_80", "HS_DC_10", "HS_DC_12",
      "HS_DC_14", "HS_DC_16", "HS_DC_18", "HS_DC_2", "HS_DC_20", "HS_DC_32", "HS_DC_4", "HS_DC_40",
      "HS_DC_6", "HS_DC_8", "HS_Gen5_10", "HS_Gen5_12", "HS_Gen5_14", "HS_Gen5_16", "HS_Gen5_18",
      "HS_Gen5_2", "HS_Gen5_20", "HS_Gen5_24", "HS_Gen5_32", "HS_Gen5_4", "HS_Gen5_40", "HS_Gen5_6",
      "HS_Gen5_8", "HS_Gen5_80", "HS_S_Gen5_10", "HS_S_Gen5_12", "HS_S_Gen5_14", "HS_S_Gen5_16",
      "HS_S_Gen5_18", "HS_S_Gen5_2", "HS_S_Gen5_20", "HS_S_Gen5_24", "HS_S_Gen5_32", "HS_S_Gen5_4",
      "HS_S_Gen5_40", "HS_S_Gen5_6", "HS_S_Gen5_8", "HS_S_Gen5_80", "P1", "P11", "P15", "P2", "P4",
      "P6", "S0", "S1", "S12", "S2", "S3", "S4", "S6", "S7", "S9"
    ], var.sku_name)
    error_message = "SKU is not valid or not supported."
}

variable "storage_account_type" {
  type        = string
  default     = "Geo"
  description = "The type of storage account for the database."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "threat_detection_policy" {
  type = object({
    state                      = string
    disabled_alerts            = list(string)
    email_account_admins       = string
    email_addresses            = list(string)
    retention_days             = number
    storage_account_access_key = string
    storage_endpoint           = string
  })
  default     = null
  description = <<DESCRIPTION
Controls the Threat Detection Policy configuration on this resource. The following properties can be specified:

- `state` - (Required) Specifies the state of the policy. Possible values are `Enabled` and `Disabled`.
- `disabled_alerts` - (Required) Specifies the list of alerts that are disabled.
- `email_account_admins` - (Required) Specifies the email address to which the alerts are sent.
- `email_addresses` - (Required) Specifies the list of email addresses to which the alerts are sent.
- `retention_days` - (Required) Specifies the number of days to keep in the Threat Detection audit logs.
- `storage_account_access_key` - (Required) Specifies the access key of the storage account to which the Threat Detection audit logs are sent.
- `storage_endpoint` - (Required) Specifies the endpoint of the storage account to which the Threat Detection audit logs are sent.
DESCRIPTION
}

variable "transparent_data_encryption_enabled" {
  type        = bool
  default     = true
  description = "Whether transparent data encryption is enabled for the database."
}

variable "transparent_data_encryption_key_automatic_rotation_enabled" {
  type        = bool
  default     = null
  description = "The key vault key name for transparent data encryption."
}

variable "transparent_data_encryption_key_vault_key_id" {
  type        = string
  default     = null
  description = "The key vault key ID for transparent data encryption."
}

variable "zone_redundant" {
  type        = bool
  default     = true
  description = "Whether the database is zone redundant."
}
