module "database" {
  source   = "./modules/database"
  for_each = var.databases

  name                                                       = each.value.name
  sql_server                                                 = { resource_id = azurerm_mssql_server.this.id }
  auto_pause_delay_in_minutes                                = each.value.auto_pause_delay_in_minutes
  collation                                                  = each.value.collation
  create_mode                                                = each.value.create_mode
  elastic_pool_id                                            = each.value.elastic_pool_key != null ? module.elasticpool[each.value.elastic_pool_key].resource_id : null
  geo_backup_enabled                                         = each.value.geo_backup_enabled
  ledger_enabled                                             = each.value.ledger_enabled
  license_type                                               = each.value.license_type
  maintenance_configuration_name                             = each.value.maintenance_configuration_name
  max_size_gb                                                = each.value.max_size_gb
  min_capacity                                               = each.value.min_capacity
  read_replica_count                                         = each.value.read_replica_count
  read_scale                                                 = each.value.read_scale
  recover_database_id                                        = each.value.recover_database_id
  restore_dropped_database_id                                = each.value.restore_dropped_database_id
  restore_point_in_time                                      = each.value.restore_point_in_time
  sample_name                                                = each.value.sample_name
  sku_name                                                   = each.value.sku_name
  storage_account_type                                       = each.value.storage_account_type
  transparent_data_encryption_enabled                        = each.value.transparent_data_encryption_enabled
  transparent_data_encryption_key_vault_key_id               = each.value.transparent_data_encryption_key_vault_key_id
  transparent_data_encryption_key_automatic_rotation_enabled = each.value.transparent_data_encryption_key_automatic_rotation_enabled
  zone_redundant                                             = each.value.zone_redundant
  import                                                     = each.value.import
  long_term_retention_policy                                 = each.value.long_term_retention_policy
  short_term_retention_policy                                = each.value.short_term_retention_policy
  threat_detection_policy                                    = each.value.threat_detection_policy
  managed_identities                                         = each.value.managed_identities
  role_assignments                                           = each.value.role_assignments
  lock                                                       = each.value.lock
  diagnostic_settings                                        = each.value.diagnostic_settings
  tags                                                       = each.value.tags
}
