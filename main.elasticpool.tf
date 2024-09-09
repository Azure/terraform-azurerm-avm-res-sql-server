resource "azurerm_mssql_elasticpool" "this" {
  for_each = var.elastic_pools

  location                       = var.location
  name                           = each.key
  resource_group_name            = var.resource_group_name
  server_name                    = try(data.azurerm_mssql_server.this[0].name, azurerm_mssql_server.this[0].name)
  license_type                   = each.value.license_type
  maintenance_configuration_name = each.value.maintenance_configuration_name
  max_size_gb                    = each.value.max_size_gb
  tags                           = var.tags
  zone_redundant                 = each.value.zone_redundant

  dynamic "per_database_settings" {
    for_each = each.value.per_database_settings != null ? { this = each.value.per_database_settings } : {}

    content {
      max_capacity = per_database_settings.value.max_capacity
      min_capacity = per_database_settings.value.min_capacity
    }
  }
  dynamic "sku" {
    for_each = each.value.sku != null ? { this = each.value.sku } : {}

    content {
      capacity = sku.value.capacity
      name     = sku.value.name
      tier     = sku.value.tier
      family   = sku.value.family
    }
  }
}