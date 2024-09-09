output "name" {
  description = "The name of the elastic pool."
    value       = azurerm_mssql_elasticpool.this.name
  
}

output "resource_id" {
  description = "The ID of the elastic pool."
    value       = azurerm_mssql_elasticpool.this.id
  
}

output "resource" {
  description = "The elastic pool."
    value       = azurerm_mssql_elasticpool.this
  
}