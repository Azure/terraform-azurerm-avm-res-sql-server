locals {
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
}

locals {
  # Azure reports a diagnostic setting with every category and category group it offers, so the
  # module sends the full set with explicit enabled flags rather than only the selected entries.
  diagnostic_categories = try(data.azapi_resource_list.diagnostic_categories[0].output.categories, [])
  available_log_categories = sort([
    for category in local.diagnostic_categories : category.name if category.category_type == "Logs"
  ])
  available_log_category_groups = sort(distinct(flatten([
    for category in local.diagnostic_categories : coalesce(category.groups, []) if category.category_type == "Logs"
  ])))
  available_metric_categories = sort([
    for category in local.diagnostic_categories : category.name if category.category_type == "Metrics"
  ])
  # Role names resolve to IDs case-insensitively. Tenant-level IDs are qualified with the subscription,
  # which is the form Azure returns, so that the configuration and the deployed assignment compare equal.
  role_definition_ids = {
    for key, assignment in var.role_assignments :
    key => can(provider::azapi::parse_resource_id("Microsoft.Authorization/roleDefinitions", assignment.role_definition_id_or_name)) ? (
      startswith(lower(assignment.role_definition_id_or_name), "/providers/") ? "/subscriptions/${provider::azapi::parse_resource_id("Microsoft.Sql/servers/databases", azurerm_mssql_database.this.id).subscription_id}${assignment.role_definition_id_or_name}" : assignment.role_definition_id_or_name
      ) : lookup(
      {
        for definition in try(data.azapi_resource_list.role_definitions[0].output.results, []) :
        lower(definition.role_name) => definition.id
      },
      lower(assignment.role_definition_id_or_name),
      null
    )
  }
}
