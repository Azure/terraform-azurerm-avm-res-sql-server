# In your output you need to select the correct resource based on the value of var.private_endpoints_manage_dns_zone_group:
output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource" {
  description = "This is the full output for the resource."
  sensitive   = true
  value       = azurerm_mssql_server.this
}

output "resource_databases" {
  description = "A map of databases. The map key is the supplied input to var.databases. The map value is the entire azurerm_mssql_database resource."
  sensitive   = true
  value       = module.database
}

output "resource_elasticpools" {
  description = "A map of elastic pools. The map key is the supplied input to var.elastic_pools. The map value is the entire azurerm_mssql_elasticpool resource."
  value       = module.elasticpool
}

output "resource_id" {
  description = "This is the id of the resource."
  value       = azurerm_mssql_server.this.id
}

output "resource_name" {
  description = "This is the name of the resource."
  value       = azurerm_mssql_server.this.name
}

output "transparent_data_encryption" {
  description = "The Transparent Data Encryption configuration for the server, including auto-rotation status. Returns null when customer-managed key is not configured."
  value = var.enable_transparent_data_encryption_with_customer_managed_key ? {
    key_vault_key_id      = var.transparent_data_encryption_key_vault_key_id
    auto_rotation_enabled = var.transparent_data_encryption_key_automatic_rotation_enabled
    resource_id           = azurerm_mssql_server_transparent_data_encryption.this[0].id
    tde_mode              = "CustomerManaged"
  } : null
}
