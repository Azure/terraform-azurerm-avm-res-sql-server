output "private_endpoints" {
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  value       = azurerm_private_endpoint.this
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = "This is the full output for the resource."
  value       = try(azurerm_mssql_server.this[0], data.azurerm_mssql_server.this[0])
}

output "resource_databases" {
  description = "A map of databases. The map key is the supplied input to var.databases. The map value is the entire azurerm_mssql_database resource."
  value       = azurerm_mssql_database.this
}

output "resource_elasticpools" {
  description = "A map of elastic pools. The map key is the supplied input to var.elastic_pools. The map value is the entire azurerm_mssql_elasticpool resource."
  value       = azurerm_mssql_elasticpool.this
}
