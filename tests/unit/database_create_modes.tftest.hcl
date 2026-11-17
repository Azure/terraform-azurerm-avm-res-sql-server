mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "azurerm" {}

variables {
  name                        = "db-test"
  enable_telemetry            = false
  creation_source_database_id = null
  sql_server = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test"
  }
}

run "recovery_preserves_recover_database_id_without_creation_source" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode         = "Recovery"
    recover_database_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/recoverabledatabases/source-db"
  }

  assert {
    condition     = var.creation_source_database_id == null && azurerm_mssql_database.this.create_mode == "Recovery" && azurerm_mssql_database.this.recover_database_id == var.recover_database_id
    error_message = "Recovery must preserve the existing recover_database_id input without requiring a replacement-triggering creation source."
  }
}

run "restore_preserves_dropped_database_id_without_creation_source" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode                 = "Restore"
    restore_dropped_database_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/restorableDroppedDatabases/source-db,132963840000000000"
  }

  assert {
    condition     = var.creation_source_database_id == null && azurerm_mssql_database.this.create_mode == "Restore" && azurerm_mssql_database.this.restore_dropped_database_id == var.restore_dropped_database_id
    error_message = "Restore must preserve the existing restore_dropped_database_id input without requiring a replacement-triggering creation source."
  }
}

run "point_in_time_restore_preserves_source_and_timestamp" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode                 = "PointInTimeRestore"
    creation_source_database_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/databases/source-db"
    restore_point_in_time       = "2026-01-01T00:00:00Z"
  }

  assert {
    condition     = azurerm_mssql_database.this.creation_source_database_id == var.creation_source_database_id && azurerm_mssql_database.this.restore_point_in_time == var.restore_point_in_time
    error_message = "Point-in-time restore must continue forwarding its source database ID and restore timestamp."
  }
}

run "copy_requires_creation_source" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode = "Copy"
  }

  expect_failures = [azurerm_mssql_database.this]
}

run "online_secondary_requires_creation_source" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode = "OnlineSecondary"
  }

  expect_failures = [azurerm_mssql_database.this]
}

run "point_in_time_restore_requires_creation_source" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode = "PointInTimeRestore"
  }

  expect_failures = [azurerm_mssql_database.this]
}

run "secondary_requires_creation_source" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode = "Secondary"
  }

  expect_failures = [azurerm_mssql_database.this]
}

run "external_backup_retains_creation_source_requirement" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode = "RestoreExternalBackup"
  }

  expect_failures = [azurerm_mssql_database.this]
}

run "external_backup_secondary_retains_creation_source_requirement" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode = "RestoreExternalBackupSecondary"
  }

  expect_failures = [azurerm_mssql_database.this]
}

run "long_term_retention_retains_creation_source_requirement" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    create_mode = "RestoreLongTermRetentionBackup"
  }

  expect_failures = [azurerm_mssql_database.this]
}
