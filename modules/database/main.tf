resource "azurerm_mssql_database" "this" {
  name                                                       = var.name
  server_id                                                  = var.sql_server.resource_id
  auto_pause_delay_in_minutes                                = var.auto_pause_delay_in_minutes
  collation                                                  = var.collation
  create_mode                                                = var.create_mode
  elastic_pool_id                                            = var.elastic_pool_id
  geo_backup_enabled                                         = var.geo_backup_enabled
  ledger_enabled                                             = var.ledger_enabled
  license_type                                               = var.license_type
  maintenance_configuration_name                             = var.maintenance_configuration_name
  max_size_gb                                                = var.max_size_gb
  min_capacity                                               = var.min_capacity
  read_replica_count                                         = var.read_replica_count
  read_scale                                                 = var.read_scale
  recover_database_id                                        = var.recover_database_id
  restore_dropped_database_id                                = var.restore_dropped_database_id
  restore_point_in_time                                      = var.restore_point_in_time
  sample_name                                                = var.sample_name
  sku_name                                                   = var.sku_name
  storage_account_type                                       = var.storage_account_type
  tags                                                       = var.tags
  transparent_data_encryption_enabled                        = var.transparent_data_encryption_enabled
  transparent_data_encryption_key_automatic_rotation_enabled = var.transparent_data_encryption_key_automatic_rotation_enabled
  transparent_data_encryption_key_vault_key_id               = var.transparent_data_encryption_key_vault_key_id
  zone_redundant                                             = var.zone_redundant

  dynamic "identity" {
    for_each = local.managed_identities.user_assigned

    content {
      identity_ids = identity.value.user_assigned_resource_ids
      type         = identity.value.type
    }
  }
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


# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_mssql_database.this.id
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_mssql_database.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azurerm_mssql_database.this.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups

    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories

    content {
      category = metric.value
    }
  }
}
