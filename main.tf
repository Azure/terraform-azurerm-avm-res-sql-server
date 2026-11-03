resource "random_password" "administrator_login_password" {
  count = var.generate_administrator_login_password && var.administrator_login_password == null ? 1 : 0

  length           = 128
  lower            = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  numeric          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
  upper            = true
}

resource "azurerm_key_vault_secret" "administrator_login_password" {
  count = var.administrator_login_password_key_vault_configuration != null && (var.administrator_login_password != null || var.generate_administrator_login_password) ? 1 : 0

  key_vault_id    = var.administrator_login_password_key_vault_configuration.key_vault_resource_id
  name            = var.administrator_login_password_key_vault_configuration.secret_name
  content_type    = var.administrator_login_password_key_vault_configuration.content_type
  expiration_date = var.administrator_login_password_key_vault_configuration.expiration_date
  tags            = var.administrator_login_password_key_vault_configuration.tags
  value           = local.administrator_login_password_effective
}

resource "azurerm_mssql_server" "this" {
  location                                     = var.location
  name                                         = var.name # calling code must supply the name
  resource_group_name                          = var.resource_group_name
  version                                      = var.server_version
  administrator_login                          = var.administrator_login
  administrator_login_password                 = local.administrator_login_password_effective
  administrator_login_password_wo              = var.administrator_login_password_wo
  administrator_login_password_wo_version      = var.administrator_login_password_wo_version
  connection_policy                            = var.connection_policy
  express_vulnerability_assessment_enabled     = var.express_vulnerability_assessment_enabled
  minimum_tls_version                          = "1.2"
  outbound_network_restriction_enabled         = var.outbound_network_restriction_enabled
  primary_user_assigned_identity_id            = var.primary_user_assigned_identity_id
  public_network_access_enabled                = var.public_network_access_enabled
  tags                                         = var.tags
  transparent_data_encryption_key_vault_key_id = var.transparent_data_encryption_key_vault_key_id

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? { this = var.azuread_administrator } : {}

    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      azuread_authentication_only = azuread_administrator.value.azuread_authentication_only
      tenant_id                   = azuread_administrator.value.tenant_id
    }
  }

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.administrator_login_password_wo != null && var.administrator_login_password_wo_version == null)
      error_message = "The variable `administrator_login_password_wo_version` must not be null when `administrator_login_password_wo` is set."
    }
    precondition {
      condition     = !(var.administrator_login_password != null && var.generate_administrator_login_password)
      error_message = "The variables `administrator_login_password` and `generate_administrator_login_password` cannot be used together. Provide `administrator_login_password` OR set `generate_administrator_login_password = true`, not both."
    }
    precondition {
      condition     = !(var.administrator_login_password_wo != null && var.generate_administrator_login_password)
      error_message = "The variables `administrator_login_password_wo` and `generate_administrator_login_password` cannot be used together. Provide `administrator_login_password_wo` OR set `generate_administrator_login_password = true`, not both."
    }
    precondition {
      condition     = !(var.administrator_login_password_key_vault_configuration != null && var.administrator_login_password_wo != null)
      error_message = "Key Vault storage is not supported when using `administrator_login_password_wo`: write-only values cannot be read back and therefore cannot be stored in Key Vault. Use `administrator_login_password` or set `generate_administrator_login_password = true` to store the password in Key Vault."
    }
    precondition {
      condition     = !(var.administrator_login_password_key_vault_configuration != null && local.administrator_login_password_effective == null && var.administrator_login_password_wo == null)
      error_message = "Cannot store the administrator login password in Key Vault because no password is available. Either set `administrator_login_password` or set `generate_administrator_login_password = true`."
    }
  }
}

# required AVM resources interfaces
resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.name}")
  parent_id = azurerm_mssql_server.this.id
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

  parent_id = azurerm_mssql_server.this.id
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
  parent_id = azurerm_mssql_server.this.id
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
      error_message = "Role assignment ${each.key} must specify a valid role definition ID or a role name available at the server scope."
    }
  }
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

data "azapi_resource_list" "diagnostic_categories" {
  count = length(var.diagnostic_settings) > 0 ? 1 : 0

  parent_id = azurerm_mssql_server.this.id
  type      = "Microsoft.Insights/diagnosticSettingsCategories@2021-05-01-preview"
  response_export_values = {
    categories = "value[].{name: name, category_type: properties.categoryType, groups: properties.categoryGroups}"
  }
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = each.value.name != null ? each.value.name : "diag-${var.name}"
  parent_id = azurerm_mssql_server.this.id
  type      = var.resource_types.insights_diagnostic_settings
  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      # Azure reports every category and category group the server offers, so each one is sent with an
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
