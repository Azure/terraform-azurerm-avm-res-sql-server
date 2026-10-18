locals {
  private_endpoint_ids = {
    for key, endpoint in merge(azurerm_private_endpoint.this, azurerm_private_endpoint.this_unmanaged_dns_zone_groups) :
    key => endpoint.id
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
