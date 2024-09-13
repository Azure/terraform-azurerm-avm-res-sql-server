module "elasticpool" {
  source   = "./modules/elasticpool"
  for_each = var.elastic_pools

  sql_server = {
    resource_id = azurerm_mssql_server.this.id
  }
  location                       = each.value.location == null ? var.location : each.value.location
  name                           = each.value.name
  license_type                   = each.value.license_type
  maintenance_configuration_name = each.value.maintenance_configuration_name
  max_size_gb                    = each.value.max_size_gb
  max_size_bytes                 = each.value.max_size_bytes
  zone_redundant                 = each.value.zone_redundant
  per_database_settings          = each.value.per_database_settings
  sku                            = each.value.sku
  role_assignments               = each.value.role_assignments
  lock                           = each.value.lock
  diagnostic_settings            = each.value.diagnostic_settings
  tags                           = each.value.tags
}
