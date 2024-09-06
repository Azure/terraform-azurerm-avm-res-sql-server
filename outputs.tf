# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  value       = try(azurerm_mssql_server.this[0], data.azurerm_mssql_server.this[0])
  description = "This is the full output for the resource."
}

output "private_endpoints" {
  value       = azurerm_private_endpoint.this
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
}

output "resource_elasticpools" {
  value       = azurerm_mssql_elasticpool.this
  description = "A map of elastic pools. The map key is the supplied input to var.elastic_pools. The map value is the entire azurerm_mssql_elasticpool resource."
}

output "resource_databases" {
  value       = azurerm_mssql_database.this
  description = "A map of databases. The map key is the supplied input to var.databases. The map value is the entire azurerm_mssql_database resource."
}