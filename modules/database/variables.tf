variable "name" {
    type        = string
    nullable    = false
    description = "The name of the database."
}

variable "sql_server" {
    type        = object({
      resource_id = string
    })
    nullable    = false
    description = "The resource ID of the SQL Server to create the database on."
}

variable "auto_pause_delay_in_minutes" {
    type        = number
    default     = null
    description = "The time in minutes before the database is automatically paused."
}

variable "create_mode" {
    type        = string
    default     = "Default"
    description = "The mode to create the database."
    validation {
      condition  = var.create_mode == null ? true : contains([
          "Copy", "Default", "OnlineSecondary", "PointInTimeRestore", "Recovery", "Restore", "RestoreExternalBackup",
          "RestoreExternalBackupSecondary", "RestoreLongTermRetentionBackup", "Secondary"
        ], var.create_mode)
        error_message = "Invalid value for create_mode. Allowed values are Copy, Default, OnlineSecondary, PointInTimeRestore, Recovery, Restore, RestoreExternalBackup, RestoreExternalBackupSecondary, RestoreLongTermRetentionBackup, or Secondary."
    }
}

variable "collation" {
    type        = string
    default     = null
    description = "The collation of the database."
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

variable "restore_point_in_time" {
    type        = string
    default     = null
    description = "The point in time to restore the database to."
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

variable "sample_name" {
    type        = string
    default     = null
    description = "The name of the sample database."
}

variable "sku_name" {
    type        = string
    default     = null
    description = "The SKU name for the database."
    validation {
      condition = var.sku_name == null || contains([
          "Basic", "BC_Gen5_2", "DS100", "DW100c", "ElasticPool", "GP_S_Gen5_2", "HS_Gen4_1", "P2", "S0"
        ], var.sku_name)
        error_message = "SKU must be one of Basic, BC_Gen5_2, DS100, DW100c, ElasticPool, GP_S_Gen5_2, HS_Gen4_1, P2, S0."
    }
}

variable "storage_account_type" {
    type        = string
    default     = "Geo"
    description = "The type of storage account for the database."
}

variable "transparent_data_encryption_enabled" {
    type        = bool
    default     = true
    description = "Whether transparent data encryption is enabled for the database."
}

variable "zone_redundant" {
    type        = bool
    default     = null
    description = "Whether the database is zone redundant."
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
    description = "The import configuration for the database."
}

variable "long_term_retention_policy" {
    type = object({
        weekly_retention  = string
        monthly_retention = string
        yearly_retention  = string
        week_of_year      = number
    })
    default     = null
    description = "The long-term retention policy for the database."
    validation {
      condition = var.long_term_retention_policy == null ? true : var.long_term_retention_policy.weekly_retention == null ? true : regex("^P(?:\\d+Y)?(?:\\d+M)?(?:\\d+W)?(?:\\d+D)?$", var.long_term_retention_policy.weekly_retention)
      error_message = "Invalid value for weekly_retention. Must be a valid ISO 8601 duration."
    }
}

variable "short_term_retention_policy" {
    type = object({
        retention_days           = number
        backup_interval_in_hours = number
    })
    default = {
        backup_interval_in_hours = 12
    }
    description = "The short-term retention policy for the database."
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
    default = {
        state                = "Disabled"
        email_account_admins = "Disabled"
    }
    description = "The threat detection policy for the database."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
