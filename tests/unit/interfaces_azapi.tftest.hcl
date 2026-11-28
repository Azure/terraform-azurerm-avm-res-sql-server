mock_provider "azapi" {
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          role_name = "Reader"
        }]
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  mock_resource "azurerm_mssql_server" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test"
    }
  }
  mock_resource "azurerm_mssql_database" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/databases/db-test"
    }
  }
  mock_resource "azurerm_mssql_elasticpool" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/elasticPools/pool-test"
    }
  }
}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"
    }
  }
}

mock_provider "time" {}

variables {
  name                = "sql-test"
  location            = "eastus"
  resource_group_name = "rg-test"
  server_version      = "12.0"
  enable_telemetry    = false
  azuread_administrator = {
    login_username              = "mock-administrator"
    object_id                   = "00000000-0000-0000-0000-000000000001"
    azuread_authentication_only = true
  }
}

run "server_lock_keeps_azurerm_name" {
  command = apply

  variables {
    lock = {
      kind = "CanNotDelete"
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-sql-test" && azapi_resource.lock[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test"
    error_message = "The server lock MUST keep the lock-<name> name and be scoped to the server."
  }

  assert {
    condition     = jsonencode(azapi_resource.lock[0].body) == jsonencode({ properties = { level = "CanNotDelete" } }) && azapi_resource.lock[0].type == "Microsoft.Authorization/locks@2020-05-01"
    error_message = "The server lock MUST send only the level, as the azurerm resource did."
  }
}

run "server_role_assignments_resolve_names_and_ids" {
  command = apply

  variables {
    role_assignments = {
      by_name = {
        role_definition_id_or_name = "reader"
        principal_id               = "00000000-0000-0000-0000-000000000002"
      }
      tenant_level_id = {
        role_definition_id_or_name       = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        principal_id                     = "00000000-0000-0000-0000-000000000003"
        skip_service_principal_aad_check = true
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["by_name"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" && azapi_resource.role_assignments["by_name"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test"
    error_message = "Role names MUST resolve case-insensitively at the server scope."
  }

  assert {
    condition     = azapi_resource.role_assignments["tenant_level_id"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" && azapi_resource.role_assignments["tenant_level_id"].body.properties.principalType == "ServicePrincipal"
    error_message = "Tenant-level IDs MUST be qualified with the subscription, and skip_service_principal_aad_check MUST send ServicePrincipal."
  }
}

run "server_role_assignment_unknown_name_fails" {
  command = plan

  variables {
    role_assignments = {
      missing = {
        role_definition_id_or_name = "Does Not Exist"
        principal_id               = "00000000-0000-0000-0000-000000000002"
      }
    }
  }

  expect_failures = [azapi_resource.role_assignments["missing"]]
}

run "server_role_assignments_keep_azurerm_defaults" {
  command = apply

  variables {
    role_assignments = {
      conditional = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000002"
        condition                  = "@Resource[Microsoft.Sql/servers:name] StringEquals 'sql-test'"
      }
      delegated = {
        role_definition_id_or_name             = "Reader"
        principal_id                           = "00000000-0000-0000-0000-000000000003"
        delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"
        skip_service_principal_aad_check       = true
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["conditional"].body.properties.conditionVersion == "2.0" && azapi_resource.role_assignments["delegated"].body.properties.conditionVersion == null
    error_message = "A condition without a version MUST send 2.0, as the AzureRM provider did."
  }

  assert {
    condition     = azapi_resource.role_assignments["conditional"].ignore_null_property
    error_message = "Null properties MUST NOT be sent, so that the principal type that Azure infers does not show as a difference."
  }

  assert {
    condition     = jsonencode(azapi_resource.role_assignments["conditional"].retry.error_message_regex) == jsonencode(["PrincipalNotFound"]) && jsonencode(azapi_resource.role_assignments["delegated"].retry.error_message_regex) == jsonencode(["PrincipalNotFound", "LinkedAuthorizationFailed"])
    error_message = "Role assignments MUST retry the replication errors that the AzureRM provider retried."
  }
}

run "server_role_assignment_retry_override" {
  command = plan

  variables {
    retry = {
      error_message_regex = ["Custom"]
    }
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000002"
      }
    }
  }

  assert {
    condition     = jsonencode(azapi_resource.role_assignments["reader"].retry.error_message_regex) == jsonencode(["Custom"])
    error_message = "A retry from the caller MUST replace the default retry."
  }
}

run "server_diagnostic_settings_send_explicit_flags" {
  command = apply

  override_data {
    target = data.azapi_resource_list.diagnostic_categories
    values = {
      output = {
        categories = [
          { name = "SQLSecurityAuditEvents", category_type = "Logs", groups = ["audit", "allLogs"] },
          { name = "DevOpsOperationsAudit", category_type = "Logs", groups = ["allLogs"] },
          { name = "AllMetrics", category_type = "Metrics", groups = null },
        ]
      }
    }
  }

  variables {
    diagnostic_settings = {
      law = {
        log_groups            = ["audit"]
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["law"].name == "diag-sql-test" && azapi_resource.diagnostic_settings["law"].type == "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
    error_message = "The diagnostic setting MUST keep the diag-<name> name."
  }

  assert {
    condition = jsonencode(azapi_resource.diagnostic_settings["law"].body.properties.logs) == jsonencode([
      { category = null, categoryGroup = "allLogs", enabled = false },
      { category = null, categoryGroup = "audit", enabled = true },
    ]) && jsonencode(azapi_resource.diagnostic_settings["law"].body.properties.metrics) == jsonencode([{ category = "AllMetrics", enabled = true }])
    error_message = "Every category group and metric MUST be sent with an explicit enabled flag."
  }
}

run "database_interfaces_use_the_database_scope" {
  command = apply

  module {
    source = "./modules/database"
  }

  override_data {
    target = data.azapi_resource_list.diagnostic_categories
    values = {
      output = {
        categories = [
          { name = "SQLInsights", category_type = "Logs", groups = ["allLogs"] },
          { name = "Basic", category_type = "Metrics", groups = null },
        ]
      }
    }
  }

  variables {
    name = "db-test"
    sql_server = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test"
    }
    lock = {
      kind = "ReadOnly"
    }
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000002"
      }
    }
    diagnostic_settings = {
      law = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
    resource_types = {
      authorization_locks = "Microsoft.Authorization/locks@2016-09-01"
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-db-test" && azapi_resource.lock[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/databases/db-test" && azapi_resource.lock[0].type == "Microsoft.Authorization/locks@2016-09-01"
    error_message = "The database lock MUST be scoped to the database and use the resource type passed in."
  }

  assert {
    condition     = azapi_resource.role_assignments["reader"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/databases/db-test" && azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    error_message = "Database role assignments MUST be scoped to the database."
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["law"].name == "diag-db-test" && jsonencode(azapi_resource.diagnostic_settings["law"].body.properties.logs) == jsonencode([{ category = null, categoryGroup = "allLogs", enabled = true }])
    error_message = "Database diagnostic settings MUST default to the allLogs group."
  }
}

run "elastic_pool_interfaces_use_the_pool_scope" {
  command = apply

  module {
    source = "./modules/elasticpool"
  }

  override_data {
    target = data.azapi_resource_list.diagnostic_categories
    values = {
      output = {
        categories = [
          { name = "AllMetrics", category_type = "Metrics", groups = null },
        ]
      }
    }
  }

  variables {
    name = "pool-test"
    sql_server = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test"
    }
    lock = {
      kind = "CanNotDelete"
    }
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000002"
      }
    }
    diagnostic_settings = {
      law = {
        log_groups            = []
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }

  assert {
    condition     = azapi_resource.lock[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/elasticPools/pool-test" && azapi_resource.role_assignments["reader"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/elasticPools/pool-test"
    error_message = "Elastic pool locks and role assignments MUST be scoped to the pool."
  }

  assert {
    condition     = jsonencode(azapi_resource.diagnostic_settings["law"].body.properties.logs) == "[]" && jsonencode(azapi_resource.diagnostic_settings["law"].body.properties.metrics) == jsonencode([{ category = "AllMetrics", enabled = true }])
    error_message = "Elastic pool diagnostic settings MUST send metrics only when no logs are selected."
  }
}
