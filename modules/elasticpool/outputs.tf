output "name" {
  depends_on  = [time_sleep.wait_for_database_deletion]
  description = "The name of the elastic pool."
  value       = azurerm_mssql_elasticpool.this.name
}

output "resource" {
  depends_on  = [time_sleep.wait_for_database_deletion]
  description = "The elastic pool."
  value       = azurerm_mssql_elasticpool.this
}

output "resource_id" {
  depends_on  = [time_sleep.wait_for_database_deletion]
  description = "The ID of the elastic pool."
  value       = azurerm_mssql_elasticpool.this.id
}
