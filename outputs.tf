output "administrator_login_password" {
  description = "The administrator login password. This value is only populated when `generate_administrator_login_password` is `true` and `administrator_login_password` is `null`. Sensitive."
  sensitive   = true
  value       = try(random_password.administrator_login_password[0].result, null)
}

output "administrator_login_password_key_vault_secret" {
  description = "The Key Vault secret resource that stores the administrator login password. Only populated when `administrator_login_password_key_vault_configuration` is set."
  sensitive   = true
  value       = try(azurerm_key_vault_secret.administrator_login_password[0], null)
}

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
