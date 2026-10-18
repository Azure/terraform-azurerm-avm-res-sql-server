resource "azurerm_private_endpoint" "this" {
  for_each = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pep-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = [coalesce(each.value.subresource_name, "sqlServer")]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = coalesce(ip_configuration.value.member_name, "sqlServer")
      subresource_name   = coalesce(each.value.subresource_name, "sqlServer")
    }
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}

# The PE resource when we are **not** managing the private_dns_zone_group block, such as when using Azure Policy:
resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pep-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = [coalesce(each.value.subresource_name, "sqlServer")]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = coalesce(ip_configuration.value.member_name, "sqlServer")
      subresource_name   = coalesce(each.value.subresource_name, "sqlServer")
    }
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = local.private_endpoint_ids[each.value.pe_key]
}

data "azapi_resource_list" "private_endpoint_role_definitions" {
  for_each = {
    for key, endpoint in var.private_endpoints : key => endpoint
    if length(endpoint.role_assignments) > 0
  }

  parent_id = local.private_endpoint_ids[each.key]
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

resource "random_uuid" "private_endpoint_role_assignment_name" {
  for_each = local.private_endpoint_role_assignments
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = local.private_endpoint_role_assignments

  name      = each.value.role.name != null ? each.value.role.name : random_uuid.private_endpoint_role_assignment_name[each.key].result
  parent_id = local.private_endpoint_ids[each.value.endpoint_key]
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      principalId                        = each.value.role.principal_id
      roleDefinitionId                   = local.private_endpoint_role_definition_ids[each.key]
      description                        = each.value.role.description
      condition                          = each.value.role.condition
      conditionVersion                   = each.value.role.condition_version
      delegatedManagedIdentityResourceId = each.value.role.delegated_managed_identity_resource_id
      principalType                      = each.value.role.principal_type != null ? each.value.role.principal_type : (each.value.role.skip_service_principal_aad_check ? "ServicePrincipal" : null)
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  replace_triggers_refs = [
    "properties.principalId",
    "properties.roleDefinitionId",
    "properties.delegatedManagedIdentityResourceId",
  ]
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = local.private_endpoint_role_definition_ids[each.key] != null
      error_message = "Private endpoint role assignment ${each.value.endpoint_key}/${each.value.role_key} must specify a valid role definition ID or a role name available at the private endpoint scope."
    }
  }
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = local.private_endpoint_locks

  name      = coalesce(each.value.name, "lock-${each.value.kind}")
  parent_id = local.private_endpoint_ids[each.key]
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = each.value.kind
      notes = each.value.notes
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azapi_resource.private_endpoint_role_assignments,
    azurerm_private_endpoint_application_security_group_association.this,
  ]
}
