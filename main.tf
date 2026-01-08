resource "azurerm_mssql_server" "this" {
  location                                     = var.location
  name                                         = var.name # calling code must supply the name
  resource_group_name                          = var.resource_group_name
  version                                      = var.server_version
  administrator_login                          = var.administrator_login
  administrator_login_password                 = coalesce(var.administrator_login_password, random_password.administrator_login_password[0].result)
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
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_mssql_server.this.id
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_mssql_server.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azurerm_mssql_server.this.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups

    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories

    content {
      category = metric.value
    }
  }
}

# Generate random password if administrator_login_password is not provided
resource "random_password" "administrator_login_password" {
  count            = var.administrator_login_password == null ? 1 : 0
  length           = 24
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  special          = true
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
}

# Store administrator_login_password in kv if administrator_login_password_key_vault_configuration is provided
# Requires that the deployment user has kv secrets write access
resource "azurerm_key_vault_secret" "administrator_login_password" {
  count        = var.administrator_login_password_key_vault_configuration != null ? 1 : 0
  key_vault_id = var.administrator_login_password_key_vault_configuration.resource_id
  value        = azurerm_mssql_server.this.administrator_login_password

  # Use the provided kv secret name, or a default if not provided
  name = coalesce(
    var.administrator_login_password_key_vault_configuration.name,
    "${var.name}-${var.administrator_login}-password"
  )
}
