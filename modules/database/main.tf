resource "azurerm_mssql_database" "this" {
  name                                = var.name
  server_id                           = var.sql_server.resource_id
  auto_pause_delay_in_minutes         = var.auto_pause_delay_in_minutes
  collation                           = var.collation
  create_mode                         = var.create_mode
  elastic_pool_id                     = var.elastic_pool_id
  geo_backup_enabled                  = var.geo_backup_enabled
  ledger_enabled                      = var.ledger_enabled
  license_type                        = var.license_type
  maintenance_configuration_name      = var.maintenance_configuration_name
  max_size_gb                         = var.max_size_gb
  min_capacity                        = var.min_capacity
  read_replica_count                  = var.read_replica_count
  read_scale                          = var.read_scale
  recover_database_id                 = var.recover_database_id
  restore_dropped_database_id         = var.restore_dropped_database_id
  restore_point_in_time               = var.restore_point_in_time
  sample_name                         = var.sample_name
  sku_name                            = var.sku_name
  storage_account_type                = var.storage_account_type
  tags                                = var.tags
  transparent_data_encryption_enabled = var.transparent_data_encryption_enabled
  zone_redundant                      = var.zone_redundant

  dynamic "import" {
    for_each = var.import != null ? { this = var.import } : {}

    content {
      administrator_login          = var.import.administrator_login
      administrator_login_password = var.import.administrator_login_password
      authentication_type          = var.import.authentication_type
      storage_key                  = var.import.storage_key
      storage_key_type             = var.import.storage_key_type
      storage_uri                  = var.import.storage_uri
      storage_account_id           = var.import.storage_account_id
    }
  }
  dynamic "long_term_retention_policy" {
    for_each = var.long_term_retention_policy != null ? { this = var.long_term_retention_policy } : {}

    content {
      monthly_retention = var.long_term_retention_policy.monthly_retention
      week_of_year      = var.long_term_retention_policy.week_of_year
      weekly_retention  = var.long_term_retention_policy.weekly_retention
      yearly_retention  = var.long_term_retention_policy.yearly_retention
    }
  }
  dynamic "short_term_retention_policy" {
    for_each = var.short_term_retention_policy != null ? { this = var.long_term_retention_policy } : {}

    content {
      retention_days           = var.short_term_retention_policy.retention_days
      backup_interval_in_hours = var.short_term_retention_policy.backup_interval_in_hours
    }
  }
  dynamic "threat_detection_policy" {
    for_each = var.threat_detection_policy != null ? { this = var.threat_detection_policy } : {}

    content {
      disabled_alerts            = var.threat_detection_policy.value.disabled_alerts
      email_account_admins       = var.threat_detection_policy.value.email_account_admins
      email_addresses            = var.threat_detection_policy.value.email_addresses
      retention_days             = var.threat_detection_policy.value.retention_days
      state                      = var.threat_detection_policy.value.state
      storage_account_access_key = var.threat_detection_policy.value.storage_account_access_key
      storage_endpoint           = var.threat_detection_policy.value.storage_endpoint
    }
  }

  lifecycle {
    precondition {
      condition     = var.elastic_pool_id == null || (var.elastic_pool_id != null && var.maintenance_configuration_name == null)
      error_message = "When creating a database resource with an elastic_pool_id, the maintenance_configuration_name is not supported at the database scope. Set this on the elastic pool instead."
    }
  }
}