# The private endpoints are split across two resources because each one is the destination of a `moved`
# block from its AzureRM counterpart, and Terraform allows only one source per destination. The two are
# configured identically: the private DNS zone group is a separate child resource in AzAPI, so the
# private endpoint itself no longer differs between the modes.
resource "azapi_resource" "private_endpoints" {
  for_each = { for key, endpoint in local.private_endpoints : key => endpoint if var.private_endpoints_manage_dns_zone_group }

  location               = each.value.location
  name                   = each.value.name
  parent_id              = each.value.parent_id
  type                   = var.resource_types.network_private_endpoints
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  response_export_values = ["properties.customDnsConfigs", "properties.networkInterfaces"]
  retry                  = var.retry
  tags                   = var.private_endpoints[each.key].tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

moved {
  from = azurerm_private_endpoint.this
  to   = azapi_resource.private_endpoints
}

# The PE resource when we are **not** managing the private DNS zone group, such as when using Azure Policy:
resource "azapi_resource" "private_endpoints_unmanaged_dns_zone_groups" {
  for_each = { for key, endpoint in local.private_endpoints : key => endpoint if !var.private_endpoints_manage_dns_zone_group }

  location               = each.value.location
  name                   = each.value.name
  parent_id              = each.value.parent_id
  type                   = var.resource_types.network_private_endpoints
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  response_export_values = ["properties.customDnsConfigs", "properties.networkInterfaces"]
  retry                  = var.retry
  tags                   = var.private_endpoints[each.key].tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

moved {
  from = azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  to   = azapi_resource.private_endpoints_unmanaged_dns_zone_groups
}

# Application security groups are part of the private endpoint's body from this version. The
# association resources the AzureRM provider used are dropped from the state without being deleted, so
# the private endpoints keep their application security groups.
removed {
  from = azurerm_private_endpoint_application_security_group_association.this

  lifecycle {
    destroy = false
  }
}

# The AzureRM provider managed the private DNS zone group inside the private endpoint. Here it is a
# child resource; on upgrade it is written again with the same name and zones.
resource "azapi_resource" "private_dns_zone_groups" {
  for_each = { for key, endpoint in var.private_endpoints : key => endpoint if var.private_endpoints_manage_dns_zone_group && length(endpoint.private_dns_zone_resource_ids) > 0 }

  name      = each.value.private_dns_zone_group_name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  body = {
    properties = {
      # Each configuration is named after its zone, as the AzureRM provider named them.
      privateDnsZoneConfigs = [
        for private_dns_zone_resource_id in each.value.private_dns_zone_resource_ids : {
          name = provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", private_dns_zone_resource_id).name
          properties = {
            privateDnsZoneId = private_dns_zone_resource_id
          }
        }
      ]
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups) > 0 ? var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups : null
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
}

# The AzureRM provider read each private endpoint's private IP address from its network interface. The
# private endpoint reports the address itself only when it is not linked to a private DNS zone, so the
# network interface is read here as well.
data "azapi_resource" "private_endpoint_network_interfaces" {
  for_each = local.private_endpoint_resources

  resource_id = each.value.output.properties.networkInterfaces[0].id
  type        = "Microsoft.Network/networkInterfaces@2024-05-01"
  response_export_values = {
    private_ip_address = "properties.ipConfigurations[0].properties.privateIPAddress"
  }
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
  # Azure returns the principal type it infers, so a null one is not sent.
  ignore_null_property = true
  replace_triggers_refs = [
    "properties.principalId",
    "properties.roleDefinitionId",
    "properties.delegatedManagedIdentityResourceId",
  ]
  response_export_values = []
  # The AzureRM provider retried while a new principal, or the link of a delegated identity, replicated.
  retry = var.retry != null ? var.retry : {
    error_message_regex  = each.value.role.delegated_managed_identity_resource_id != null && each.value.role.skip_service_principal_aad_check ? ["PrincipalNotFound", "LinkedAuthorizationFailed"] : ["PrincipalNotFound"]
    interval_seconds     = null
    max_interval_seconds = null
  }

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
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoint_role_assignments,
  ]
}
