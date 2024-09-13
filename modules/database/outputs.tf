output "name" {
  description = "The name of the SQL database."
  value       = azurerm_mssql_database.this.name
}

output "resource" {
  description = "The full resource object of the SQL database."
  value       = azurerm_mssql_database.this
}

output "resource_id" {
  description = "The resource ID of the SQL database."
  value       = azurerm_mssql_database.this.id
}
