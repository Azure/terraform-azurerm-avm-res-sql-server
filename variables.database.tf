variable "databases" {
  description = <<DATABASES
A map of objects used to describe any databases that are being created.  The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (required) The name to use for the database
- `auto_pause_delay_in_minutes` - (Optional) - Time in minutes after which database is automatically paused.  A value of `-1` means that automatic pause is disabled.  This property is only settable for Serverless databases.
- `create_mode` - (Optional) - The create mode of the database. Possible values are `Copy`, `Default`, `OnlineSecondary`, `PointInTimeRestore`, `Recovery`, `Restore`, `RestoreExternalBackup`, `RestoreExternalBackupSecondary`, `RestoreLongTermRetentionBackup`, and `Secondary`.  Mutually exclusive with `import`.  Changing this forces a new resource to be created.  Defaults to `Default`.
- `elastic_pool_key` - (Optional) - The map key of the elastic pool containing this database.
- `geo_backup_enabled` - (Optional) - A boolean that specifies if the Geo Backup Policy is enabled. Default to `true`.
- `maintenance_configuration_name` -  (Optional) The name of the Public Maintenance Configuration window to apply to the database. Valid values include `SQL_Default`, `SQL_EastUS_DB_1`, `SQL_EastUS2_DB_1`, `SQL_SoutheastAsia_DB_1`, `SQL_AustraliaEast_DB_1`, `SQL_NorthEurope_DB_1`, `SQL_SouthCentralUS_DB_1`, `SQL_WestUS2_DB_1`, `SQL_UKSouth_DB_1`, `SQL_WestEurope_DB_1`, `SQL_EastUS_DB_2`, `SQL_EastUS2_DB_2`, `SQL_WestUS2_DB_2`, `SQL_SoutheastAsia_DB_2`, `SQL_AustraliaEast_DB_2`, `SQL_NorthEurope_DB_2`, `SQL_SouthCentralUS_DB_2`, `SQL_UKSouth_DB_2`, `SQL_WestEurope_DB_2`, `SQL_AustraliaSoutheast_DB_1`, `SQL_BrazilSouth_DB_1`, `SQL_CanadaCentral_DB_1`, `SQL_CanadaEast_DB_1`, `SQL_CentralUS_DB_1`, `SQL_EastAsia_DB_1`, `SQL_FranceCentral_DB_1`, `SQL_GermanyWestCentral_DB_1`, `SQL_CentralIndia_DB_1`, `SQL_SouthIndia_DB_1`, `SQL_JapanEast_DB_1`, `SQL_JapanWest_DB_1`, `SQL_NorthCentralUS_DB_1`, `SQL_UKWest_DB_1`, `SQL_WestUS_DB_1`, `SQL_AustraliaSoutheast_DB_2`, `SQL_BrazilSouth_DB_2`, `SQL_CanadaCentral_DB_2`, `SQL_CanadaEast_DB_2`, `SQL_CentralUS_DB_2`, `SQL_EastAsia_DB_2`, `SQL_FranceCentral_DB_2`, `SQL_GermanyWestCentral_DB_2`, `SQL_CentralIndia_DB_2`, `SQL_SouthIndia_DB_2`, `SQL_JapanEast_DB_2`, `SQL_JapanWest_DB_2`, `SQL_NorthCentralUS_DB_2`, `SQL_UKWest_DB_2`, `SQL_WestUS_DB_2`, `SQL_WestCentralUS_DB_1`, `SQL_FranceSouth_DB_1`, `SQL_WestCentralUS_DB_2`, `SQL_FranceSouth_DB_2`, `SQL_SwitzerlandNorth_DB_1`, `SQL_SwitzerlandNorth_DB_2`, `SQL_BrazilSoutheast_DB_1`, `SQL_UAENorth_DB_1`, `SQL_BrazilSoutheast_DB_2`, `SQL_UAENorth_DB_2`. Defaults to `SQL_Default`.
- `ledger_enabled` - (Optional) - A boolean that specifies if this is a ledger database. Defaults to `false`. Changing this forces a new resource to be created.
- `license_type` - (Optional) - Specifies the license type applied to this database. Possible values are `LicenseIncluded` and `BasePrice.`
- `max_size_gb` - (Optional) - The max size of the database in gigabytes.
- `min_capacity` - (Optional) - Minimal capacity that database will always have allocated, if not paused. This property is only settable for Serverless databases.
- `restore_point_in_time` - (Optional) - Specifies the point in time (ISO8601 format) of the source database that will be restored to create the new database. This property is only settable for `create_mode` = `PointInTimeRestore` databases.
- `recover_database_id` - (Optional) - The ID of the database to be recovered. This property is only applicable when the `create_mode` is `Recovery`.
- `restore_dropped_database_id` - (Optional) - The ID of the database to be restored. This property is only applicable when the `create_mode` is `Restore`.
- `read_replica_count` - (Optional) - The number of readonly secondary replicas associated with the database to which readonly application intent connections may be routed. This property is only settable for Hyperscale edition databases.
- `read_scale` - (Optional) - If enabled, connections that have application intent set to readonly in their connection string may be routed to a readonly secondary replica. This property is only settable for Premium and Business Critical databases.
- `sample_name` - (Optional) - Specifies the name of the sample schema to apply when creating this database. Possible value is `AdventureWorksLT`.
- `sku_name` - (Optional) - Specifies the name of the SKU used by the database. For example, `GP_S_Gen5_2`,`HS_Gen4_1`,`BC_Gen5_2`, `ElasticPool`, `Basic`,`S0`, `P2` ,`DW100c`, `DS100`. Changing this from the HyperScale service tier to another service tier will create a new resource.
- `storage_account_type` - (Optional) -Specifies the storage account type used to store backups for this database. Possible values are `Geo`, `GeoZone`, `Local and Zone`. Defaults to `Geo`.
- `transparent_data_encryption_enabled` - If set to true, Transparent Data Encryption will be enabled on the database. Defaults to `true`. `transparent_data_encryption_enabled` can only be set to `false` on DW (e.g, DataWarehouse) server SKUs.
- `zone_redundant` - Whether or not this database is zone redundant, which means the replicas of this database will be spread across multiple availability zones. This property is only settable for Premium and Business Critical databases.

- `import` - (Optional(object({
  - `storage_uri` - (Required) - Specifies the blob URI of the .bacpac file.
  - `storage_key` - (Required) - Specifies the access key for the storage account.
  - `storage_key_type` - (Required) - Specifies the type of access key for the storage account. Valid values are `StorageAccessKey` or `SharedAccessKey`.
  - `administrator_login` - (Required) - Specifies the name of the SQL administrator.
  - `administrator_password` - (Required) - Specifies the password of the SQL administrator.
  - `authentication_type` - (Required) - Specifies the type of authentication used to access the server. Valid values are `SQL` or `ADPassword`.
  - `storage_account_id` - (Optional) - The resource id for the storage account used to store BACPAC file. If set, private endpoint connection will be created for the storage account. Must match storage account used for storage_uri parameter.

- `long_term_retention_policy - (Optional(object({
  - `weekly_retention` - (Optional) - The weekly retention policy for an LTR backup in an ISO 8601 format. Valid value is between 1 to 520 weeks. e.g. `P1Y`, `P1M`, `P1W` or `P7D`.
  - `monthly_retention` - (Optional) - The monthly retention policy for an LTR backup in an ISO 8601 format. Valid value is between 1 to 120 months. e.g. `P1Y`, `P1M`, `P4W` or `P30D`.
  - `yearly_retention` - (Optional) - The yearly retention policy for an LTR backup in an ISO 8601 format. Valid value is between 1 to 10 years. e.g. `P1Y`, `P12M`, `P52W` or `P365D`.
  - `week_of_year` - (Optional) - The week of year to take the yearly backup. Value has to be between `1` and `52`.

- `short_term_retention_policy - (Optional(object({
  - `retention_days` - (Required) - Point In Time Restore configuration. Value has to be between `1` and `35`.
  - `backup_interval_in_hours` - (Optional) - The hours between each differential backup. This is only applicable to live databases but not dropped databases. Value has to be `12` or `24`. Defaults to `12` hours.

- `threat_detection_policy - (Optional(object({
  - `state` - (Optional) - The State of the Policy. Possible values are `Enabled` or `Disabled`. Defaults to `Disabled`.
  - `disabled_alerts` - (Optional) - Specifies a list of alerts which should be disabled. Possible values include `Access_Anomaly`, `Sql_Injection` and `Sql_Injection_Vulnerability`.
  - `email_account_admins` - (Optional) - Should the account administrators be emailed when this alert is triggered? Possible values are `Enabled` or `Disabled`. Defaults to `Disabled`.
  - `email_addresses` - (Optional) - A list of email addresses which alerts should be sent to.
  - `retention_days` - (Optional) - Specifies the number of days to keep in the Threat Detection audit logs.
  - `storage_account_access_key` - (Optional) - (Optional) Specifies the identifier key of the Threat Detection audit storage account. Required if `state` is `Enabled`.
  - `storage_endpoint` - (Optional) - Specifies the blob storage endpoint (e.g. https://example.blob.core.windows.net). This blob storage will hold all Threat Detection audit logs. Required if `state` is `Enabled`.

- `role_assignments - (Optional(map(object({
  - `role_definition_id_or_name` - (Required) - The ID or Name of the Role Definition to assign.
  - `principal_id` - (Required) - The ID of the Principal to assign the Role Definition to.
  - `description` - (Optional) - A description of the Role Assignment.
  - `skip_service_principal_aad_check` - (Optional) - Should the AAD check for Service Principals be skipped? Defaults to `false`.
  - `condition` - (Optional) - The condition of the Role Assignment.
  - `condition_version` - (Optional) - The condition version of the Role Assignment.
  - `delegated_managed_identity_resource_id` - (Optional) - The Resource ID of the Delegated Managed Identity.
  - `principal_type` - (Optional) - The type of the Principal. Possible values are `User`, `Group`, `ServicePrincipal` or `DirectoryRoleTemplate`.

- `lock - (Optional(object({
  - `kind` - (Required) - The kind of lock. Possible values are `ReadOnly` and `CanNotDelete`.
  - `name` - (Optional) - The name of the lock.

- `diagnostic_settings - (Optional(map(object({
  - `name` - (Optional) - The name of the Diagnostic Setting.
  - `event_hub_authorization_rule_id` - (Optional) - The ID of the Event Hub Authorization Rule.
  - `event_hub_name` - (Optional) - The name of the Event Hub.
  - `log_analytics_destination_type` - (Optional) - The type of the Log Analytics Destination. Possible values are `Dedicated` and `Shared`.
  - `log_analytics_workspace_id` - (Optional) - The ID of the Log Analytics Workspace.
  - `marketplace_partner_resource_id` - (Optional) - The ID of the Marketplace Partner Resource.
  - `storage_account_resource_id` - (Optional) - The ID of the Storage Account.
  - `log_categories` - (Optional) - A list of log categories to send to the destination.
  - `log_groups` - (Optional) - A list of log groups to send to the destination.

- `managed_identities - (Optional(object({
  - `system_assigned` - (Optional) - Is the system assigned managed identity enabled? Defaults to `false`.
  - `user_assigned_resource_ids` - (Optional) - A list of User Assigned Managed Identity Resource IDs.

- `tags` - Optional - Map of strings for use in tagging this specific object

EXAMPLE INPUT: 

databases = {
  example_database = {
    name = "example_database"
    long_term_retention_policy = {
      weekly_retention = "P1W"
    }
    short_term_retention_policy = {
      retention_days = 35
      backup_interval_in_hours = 24
    }
  }
}
  
DATABASES

  type = map(object({
    name                                                       = string
    auto_pause_delay_in_minutes                                = optional(number)
    create_mode                                                = optional(string, "Default")
    collation                                                  = optional(string)
    elastic_pool_key                                           = optional(string)
    geo_backup_enabled                                         = optional(bool, true)
    maintenance_configuration_name                             = optional(string)
    ledger_enabled                                             = optional(bool, false)
    license_type                                               = optional(string)
    max_size_gb                                                = optional(number)
    min_capacity                                               = optional(number)
    restore_point_in_time                                      = optional(string)
    recover_database_id                                        = optional(string)
    restore_dropped_database_id                                = optional(string)
    read_replica_count                                         = optional(number)
    read_scale                                                 = optional(bool)
    sample_name                                                = optional(string)
    sku_name                                                   = optional(string)
    storage_account_type                                       = optional(string, "Geo")
    transparent_data_encryption_enabled                        = optional(bool, true)
    transparent_data_encryption_key_vault_key_id               = optional(string)
    transparent_data_encryption_key_automatic_rotation_enabled = optional(bool)
    zone_redundant                                             = optional(bool)

    import = optional(object({
      storage_uri            = string
      storage_key            = string
      storage_key_type       = string
      administrator_login    = string
      administrator_password = string
      authentication_type    = string
      storage_account_id     = optional(string)
    }))

    long_term_retention_policy = optional(object({
      weekly_retention  = string
      monthly_retention = string
      yearly_retention  = string
      week_of_year      = number
    }))

    short_term_retention_policy = optional(object({
      retention_days           = number
      backup_interval_in_hours = optional(number, 12)
    }))

    threat_detection_policy = optional(object({
      state                      = optional(string, "Disabled")
      disabled_alerts            = optional(list(string))
      email_account_admins       = optional(string, "Disabled")
      email_addresses            = optional(list(string))
      retention_days             = optional(number)
      storage_account_access_key = optional(string)
      storage_endpoint           = optional(string)
    }))

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })))

    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))

    diagnostic_settings = optional(map(object({
      name                            = optional(string, null)
      event_hub_authorization_rule_id = optional(string, null)
      event_hub_name                  = optional(string, null)
      log_analytics_destination_type  = optional(string, null)
      log_analytics_workspace_id      = optional(string, null)
      marketplace_partner_resource_id = optional(string, null)
      storage_account_resource_id     = optional(string, null)
      log_categories                  = optional(list(string))
      log_groups                      = optional(list(string))
    })))

    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
    }))

    tags = optional(map(string))
  }))
  default = {}
}
