resource "azurerm_mssql_elasticpool" "this" {
  for_each = var.elastic_pools

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = coalesce(var.location, data.azurerm_resource_group.parent[0].location)
  server_name         = try(data.azurerm_mssql_server.this[0].name, azurerm_mssql_server.this[0].name)

  license_type                   = each.value.license_type
  max_size_gb                    = each.value.max_size_gb
  maintenance_configuration_name = each.value.maintenance_configuration_name
  zone_redundant                 = each.value.zone_redundant

  dynamic "sku" {
    for_each = each.value.sku != null ? { this = each.value.sku } : {}
    content {
      name     = sku.value.name
      tier     = sku.value.tier
      family   = sku.value.family
      capacity = sku.value.capacity
    }
  }

  dynamic "per_database_settings" {
    for_each = each.value.per_database_settings != null ? { this = each.value.per_database_settings } : {}
    content {
      min_capacity = per_database_settings.value.min_capacity
      max_capacity = per_database_settings.value.max_capacity
    }
  }

  tags = var.tags
}