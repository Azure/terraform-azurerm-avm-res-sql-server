locals {
  private_endpoint_ids = {
    for key, endpoint in local.private_endpoint_resources :
    key => endpoint.id
  }
  # Every private endpoint, whichever of the two resources in main.privateendpoint.tf manages it.
  private_endpoint_resources = merge(azapi_resource.private_endpoints, azapi_resource.private_endpoints_unmanaged_dns_zone_groups)
  # The configuration of each private endpoint. It reproduces what the AzureRM provider sent, so that
  # upgrading moves the existing private endpoints without changing them.
  private_endpoints = {
    for key, endpoint in var.private_endpoints : key => {
      body = {
        properties = merge(
          {
            # Empty lists are sent rather than omitted, so that removing the last application security
            # group or IP configuration removes it from Azure.
            applicationSecurityGroups = [
              for asg_resource_id in values(endpoint.application_security_group_associations) : { id = asg_resource_id }
            ]
            ipConfigurations = [
              for ip_configuration in values(endpoint.ip_configurations) : {
                name = ip_configuration.name
                properties = {
                  groupId          = coalesce(endpoint.subresource_name, "sqlServer")
                  memberName       = coalesce(ip_configuration.member_name, "sqlServer")
                  privateIPAddress = ip_configuration.private_ip_address
                }
              }
            ]
            privateLinkServiceConnections = [
              {
                name = endpoint.private_service_connection_name != null ? endpoint.private_service_connection_name : "pse-${var.name}"
                properties = {
                  groupIds             = [coalesce(endpoint.subresource_name, "sqlServer")]
                  privateLinkServiceId = azurerm_mssql_server.this.id
                }
              }
            ]
            subnet = {
              id = endpoint.subnet_resource_id
            }
          },
          # Azure stores an unset custom network interface name as an empty string, so the property is
          # sent only when it is set. Sending null would report a difference on every plan.
          endpoint.network_interface_name == null ? {} : { customNetworkInterfaceName = endpoint.network_interface_name },
        )
      }
      location = endpoint.location != null ? endpoint.location : var.location
      name     = endpoint.name != null ? endpoint.name : "pep-${var.name}"
      # `resource_group_name` is a resource group in the server's subscription, as it was with the
      # AzureRM provider.
      parent_id = "/subscriptions/${provider::azapi::parse_resource_id("Microsoft.Sql/servers", azurerm_mssql_server.this.id).subscription_id}/resourceGroups/${endpoint.resource_group_name != null ? endpoint.resource_group_name : var.resource_group_name}"
    }
  }
  private_endpoint_lock_configuration = {
    for key, endpoint in var.private_endpoints :
    key => endpoint.lock != null ? endpoint.lock : (var.lock == null ? null : merge(var.lock, { notes = null }))
  }
  private_endpoint_locks = {
    for key, lock in local.private_endpoint_lock_configuration :
    key => lock if lock == null ? false : lock.kind != "None"
  }
  private_endpoint_role_assignments = {
    for assignment in flatten([
      for endpoint_key, endpoint in var.private_endpoints : [
        for role_key, role in endpoint.role_assignments : {
          endpoint_key = endpoint_key
          role_key     = role_key
          role         = role
        }
      ]
    ]) : jsonencode([assignment.endpoint_key, assignment.role_key]) => assignment
  }
  private_endpoint_role_definition_ids = {
    for key, assignment in local.private_endpoint_role_assignments :
    key => can(provider::azapi::parse_resource_id("Microsoft.Authorization/roleDefinitions", assignment.role.role_definition_id_or_name)) ? assignment.role.role_definition_id_or_name : lookup(
      {
        for definition in data.azapi_resource_list.private_endpoint_role_definitions[assignment.endpoint_key].output.results :
        lower(definition.role_name) => definition.id
      },
      lower(assignment.role.role_definition_id_or_name),
      null
    )
  }
}
