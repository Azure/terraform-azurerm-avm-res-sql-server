output "administrator_login_password_key_vault_secret" {
  description = "The Key Vault secret resource that stores the administrator login password. Only populated when `administrator_login_password_key_vault_configuration` is set."
  sensitive   = true
  value       = try(azurerm_key_vault_secret.administrator_login_password[0], null)
}

output "generated_administrator_login_password" {
  description = "The auto-generated administrator login password. Only populated when `generate_administrator_login_password = true`; null in all other cases (including when the password was supplied via `administrator_login_password` or `administrator_login_password_wo`). Sensitive."
  sensitive   = true
  value       = try(random_password.administrator_login_password[0].result, null)
}

# In your output you need to select the correct resource based on the value of var.private_endpoints_manage_dns_zone_group:
output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  # The AzureRM attribute names and shapes are kept so that references such as
  # `private_service_connection[0].private_ip_address` keep working.
  value = {
    for key, endpoint in local.private_endpoint_resources : key => {
      custom_dns_configs = [
        for config in try(endpoint.output.properties.customDnsConfigs, []) : {
          fqdn         = config.fqdn
          ip_addresses = config.ipAddresses
        }
      ]
      custom_network_interface_name = var.private_endpoints[key].network_interface_name
      id                            = endpoint.id
      ip_configuration = [
        for ip_configuration in values(var.private_endpoints[key].ip_configurations) : {
          member_name        = coalesce(ip_configuration.member_name, "sqlServer")
          name               = ip_configuration.name
          private_ip_address = ip_configuration.private_ip_address
          subresource_name   = coalesce(var.private_endpoints[key].subresource_name, "sqlServer")
        }
      ]
      location = endpoint.location
      name     = endpoint.name
      network_interface = [
        for nic in try(endpoint.output.properties.networkInterfaces, []) : {
          id   = nic.id
          name = provider::azapi::parse_resource_id("Microsoft.Network/networkInterfaces", nic.id).name
        }
      ]
      private_dns_zone_group = [
        for group in try([azapi_resource.private_dns_zone_groups[key]], []) : {
          id                   = group.id
          name                 = group.name
          private_dns_zone_ids = tolist(var.private_endpoints[key].private_dns_zone_resource_ids)
        }
      ]
      private_service_connection = [
        {
          is_manual_connection           = false
          name                           = local.private_endpoints[key].body.properties.privateLinkServiceConnections[0].name
          private_connection_resource_id = azurerm_mssql_server.this.id
          private_ip_address             = try(data.azapi_resource.private_endpoint_network_interfaces[key].output.private_ip_address, null)
          subresource_names              = tolist(local.private_endpoints[key].body.properties.privateLinkServiceConnections[0].properties.groupIds)
        }
      ]
      resource_group_name = var.private_endpoints[key].resource_group_name != null ? var.private_endpoints[key].resource_group_name : var.resource_group_name
      subnet_id           = var.private_endpoints[key].subnet_resource_id
      tags                = endpoint.tags
    }
  }
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
