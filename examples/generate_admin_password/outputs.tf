output "admin_password_key_vault_secret_id" {
  description = "The Key Vault secret ID where the administrator password is stored."
  sensitive   = true
  value       = module.sql_server.administrator_login_password_key_vault_secret.id
}

output "sql_server_id" {
  description = "The resource ID of the SQL Server."
  value       = module.sql_server.resource_id
}
