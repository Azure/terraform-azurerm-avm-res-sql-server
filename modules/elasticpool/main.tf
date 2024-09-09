resource "azurerm_mssql_elasticpool" "this" {
  location                       = var.location
  name                           = var.name
  resource_group_name            = local.resource_group_name
  server_name                    = local.sql_server_name
  license_type                   = var.license_type
  maintenance_configuration_name = var.maintenance_configuration_name
  max_size_bytes                 = var.max_size_bytes
  max_size_gb                    = var.max_size_gb
  tags                           = var.tags
  zone_redundant                 = var.zone_redundant

  per_database_settings {
    max_capacity = var.per_database_settings.max_capacity
    min_capacity = var.per_database_settings.min_capacity
  }
  sku {
    capacity = var.sku.capacity
    name     = var.name
    tier     = sku.value.tier
    family   = sku.value.family
  }
}