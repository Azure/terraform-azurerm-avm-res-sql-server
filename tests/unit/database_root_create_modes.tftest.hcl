mock_provider "azapi" {
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
}

mock_provider "random" {}
mock_provider "time" {}

run "root_forwards_existing_recovery_and_restore_inputs" {
  command = plan

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
    databases = {
      recovery = {
        name                = "db-recovery"
        create_mode         = "Recovery"
        recover_database_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/recoverabledatabases/source-db"
      }
      restore = {
        name                        = "db-restore"
        create_mode                 = "Restore"
        restore_dropped_database_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/restorableDroppedDatabases/source-db,132963840000000000"
      }
    }
  }

  assert {
    condition     = var.databases["recovery"].creation_source_database_id == null && module.database["recovery"].resource.create_mode == "Recovery" && module.database["recovery"].resource.recover_database_id == var.databases["recovery"].recover_database_id
    error_message = "The root must preserve Recovery and its existing recover_database_id without adding a creation source."
  }

  assert {
    condition     = var.databases["restore"].creation_source_database_id == null && module.database["restore"].resource.create_mode == "Restore" && module.database["restore"].resource.restore_dropped_database_id == var.databases["restore"].restore_dropped_database_id
    error_message = "The root must preserve Restore and its existing restore_dropped_database_id without adding a creation source."
  }
}
