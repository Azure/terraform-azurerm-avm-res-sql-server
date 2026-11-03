resource "azurerm_mssql_elasticpool" "this" {
  location                       = var.location
  name                           = var.name
  resource_group_name            = local.resource_group_name
  server_name                    = local.sql_server_name
  license_type                   = var.license_type
  maintenance_configuration_name = var.maintenance_configuration_name
  max_size_bytes                 = var.max_size_bytes
  max_size_gb                    = var.max_size_gb
  tags                           = var.tags
  zone_redundant                 = var.zone_redundant

  per_database_settings {
    max_capacity = var.per_database_settings.max_capacity
    min_capacity = var.per_database_settings.min_capacity
  }

  sku {
    capacity = var.sku.capacity
    name     = var.sku.name
    tier     = var.sku.tier
    family   = var.sku.family
  }
}

# Azure can briefly retain pool membership after database deletion completes.
resource "time_sleep" "wait_for_database_deletion" {
  destroy_duration = "60s"

  depends_on = [azurerm_mssql_elasticpool.this]
}

# required AVM resources interfaces
resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.name}")
  parent_id = azurerm_mssql_elasticpool.this.id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = var.lock.kind
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

  # Create the lock last and remove it first, so it does not block changes to the other resources.
  depends_on = [
    azapi_resource.diagnostic_settings,
    azapi_resource.role_assignments,
  ]
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

data "azapi_resource_list" "role_definitions" {
  count = length(var.role_assignments) > 0 ? 1 : 0

  parent_id = azurerm_mssql_elasticpool.this.id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

resource "random_uuid" "role_assignment_name" {
  for_each = var.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name      = random_uuid.role_assignment_name[each.key].result
  parent_id = azurerm_mssql_elasticpool.this.id
  type      = var.resource_types.authorization_role_assignments
  # The AzureRM provider sent conditionVersion 2.0 when a condition had no version.
  body = {
    properties = {
      principalId                        = each.value.principal_id
      roleDefinitionId                   = local.role_definition_ids[each.key]
      description                        = each.value.description
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition != null && each.value.condition_version == null ? "2.0" : each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
      principalType                      = each.value.principal_type != null ? each.value.principal_type : (each.value.skip_service_principal_aad_check ? "ServicePrincipal" : null)
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
    error_message_regex  = each.value.delegated_managed_identity_resource_id != null && each.value.skip_service_principal_aad_check ? ["PrincipalNotFound", "LinkedAuthorizationFailed"] : ["PrincipalNotFound"]
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
    # Upgraded assignments keep the name the AzureRM provider generated.
    ignore_changes = [name]

    precondition {
      condition     = local.role_definition_ids[each.key] != null
      error_message = "Role assignment ${each.key} must specify a valid role definition ID or a role name available at the elastic pool scope."
    }
  }
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

data "azapi_resource_list" "diagnostic_categories" {
  count = length(var.diagnostic_settings) > 0 ? 1 : 0

  parent_id = azurerm_mssql_elasticpool.this.id
  type      = "Microsoft.Insights/diagnosticSettingsCategories@2021-05-01-preview"
  response_export_values = {
    categories = "value[].{name: name, category_type: properties.categoryType, groups: properties.categoryGroups}"
  }
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = each.value.name != null ? each.value.name : "diag-${var.name}"
  parent_id = azurerm_mssql_elasticpool.this.id
  type      = var.resource_types.insights_diagnostic_settings
  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      # Azure reports every category and category group the elastic pool offers, so each one is sent with an
      # explicit flag. Sending only the enabled entries would report a difference on every plan.
      logs = tolist(concat(
        [for group in local.available_log_category_groups : {
          category      = null
          categoryGroup = group
          enabled       = contains(each.value.log_groups, group)
        } if length(each.value.log_groups) > 0],
        [for category in local.available_log_categories : {
          category      = category
          categoryGroup = null
          enabled       = contains(each.value.log_categories, category)
        } if length(each.value.log_categories) > 0],
      ))
      marketplacePartnerId = each.value.marketplace_partner_resource_id
      metrics = tolist([for category in local.available_metric_categories : {
        category = category
        enabled  = contains(each.value.metric_categories, category)
      }])
      storageAccountId = each.value.storage_account_resource_id
      workspaceId      = each.value.workspace_resource_id
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  ignore_null_property   = true
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

moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}
