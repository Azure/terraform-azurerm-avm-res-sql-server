variable "databases" {
  description = "Map of databases."

  type = map(object({
    auto_pause_delay_in_minutes         = optional(number)
    create_mode                         = optional(string, "Default")
    collation                           = optional(string)
    elastic_pool_id                     = optional(string)
    geo_backup_enabled                  = optional(bool, true)
    maintenance_configuration_name      = optional(string)
    ledger_enabled                      = optional(bool, false)
    license_type                        = optional(string)
    max_size_gb                         = optional(number)
    min_capacity                        = optional(number)
    restore_point_in_time               = optional(string)
    recover_database_id                 = optional(string)
    restore_dropped_database_id         = optional(string)
    read_replica_count                  = optional(number)
    read_scale                          = optional(bool)
    sample_name                         = optional(string)
    sku_name                            = optional(string)
    storage_account_type                = optional(string, "Geo")
    transparent_data_encryption_enabled = optional(bool, true)
    zone_redundant                      = optional(bool)

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

    short_term_retention_policy = object({
      retention_days           = number
      backup_interval_in_hours = optional(number, 12)
    })

    threat_detection_policy = optional(object({
      state                      = optional(string, "Disabled")
      disabled_alerts            = optional(list(string))
      email_account_admins       = optional(string, "Disabled")
      email_addresses            = optional(list(string))
      retention_days             = optional(number)
      storage_account_access_key = optional(string)
      storage_endpoint           = optional(string)
    }))


    tags = optional(map(string))
  }))

  validation {
    condition = can([
      for database, config in var.databases : (
        config.create_mode == null ? true : contains([
          "Copy", "Default", "OnlineSecondary", "PointInTimeRestore", "Recovery", "Restore", "RestoreExternalBackup",
          "RestoreExternalBackupSecondary", "RestoreLongTermRetentionBackup", "Secondary"
        ], config.create_mode)
      )
    ])
    error_message = "Invalid value for create_mode. Allowed values are Copy, Default, OnlineSecondary, PointInTimeRestore, Recovery, Restore, RestoreExternalBackup, RestoreExternalBackupSecondary, RestoreLongTermRetentionBackup, or Secondary."
  }

  validation {
    condition = can([
      for database, config in var.databases : (
        config.maintenance_configuration_name == null ? true : contains([
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
        ], config.maintenance_configuration_name)
      )
    ])
    error_message = "Invalid value for maintenance_configuration_name."
  }

  validation {
    condition = can([
      for database, config in var.databases : (
        config.sku_name == null || contains([
          "Basic", "BC_Gen5_2", "DS100", "DW100c", "ElasticPool", "GP_S_Gen5_2", "HS_Gen4_1", "P2", "S0",
          # Add more SKU names as needed
        ], config.sku_name)
      )
    ])
    error_message = "Invalid value for sku_name. Allowed values are Basic, BC_Gen5_2, DS100, DW100c, ElasticPool, GP_S_Gen5_2, HS_Gen4_1, P2, S0, ... (add more as needed)."
  }

  validation {
    condition = can([
      for database, config in var.databases : (
        config.long_term_retention_policy == null ? true : config.long_term_retention_policy.weekly_retention == null ? true : regex("^P(?:\\d+Y)?(?:\\d+M)?(?:\\d+W)?(?:\\d+D)?$", config.long_term_retention_policy.weekly_retention)
      )
    ])
    error_message = "'long_term_retention_policy.weekly_retention' should be in ISO 8601 format (e.g., P1Y, P1M, P1W, or P7D)."
  }

  default = {}
}