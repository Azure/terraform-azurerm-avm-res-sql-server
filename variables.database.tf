variable "databases" {
  description = "Map of databases."

  type = map(object({
    name                                = string
    auto_pause_delay_in_minutes         = optional(number)
    create_mode                         = optional(string, "Default")
    collation                           = optional(string)
    elastic_pool_key                    = optional(string)
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
  default = {}
}
