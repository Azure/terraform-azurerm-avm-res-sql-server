module "elasticpool" {
  source   = "./modules/elasticpool"
  for_each = var.elastic_pools

  location = each.value.location == null ? var.location : each.value.location
  name     = each.value.name
  sql_server = {
    resource_id = azurerm_mssql_server.this.id
  }
  diagnostic_settings = each.value.diagnostic_settings
  enable_telemetry    = var.enable_telemetry
  ignore_body_changes = {
    authorization_locks            = var.ignore_body_changes.authorization_locks
    authorization_role_assignments = var.ignore_body_changes.authorization_role_assignments
    insights_diagnostic_settings   = var.ignore_body_changes.insights_diagnostic_settings
  }
  license_type                   = each.value.license_type
  lock                           = each.value.lock
  maintenance_configuration_name = each.value.maintenance_configuration_name
  max_size_bytes                 = each.value.max_size_bytes
  max_size_gb                    = each.value.max_size_gb
  per_database_settings          = each.value.per_database_settings
  resource_types = {
    authorization_locks            = var.resource_types.authorization_locks
    authorization_role_assignments = var.resource_types.authorization_role_assignments
    insights_diagnostic_settings   = var.resource_types.insights_diagnostic_settings
  }
  retry            = var.retry
  role_assignments = each.value.role_assignments
  sku              = each.value.sku
  tags             = each.value.tags
  timeouts         = var.timeouts
  zone_redundant   = each.value.zone_redundant
}
