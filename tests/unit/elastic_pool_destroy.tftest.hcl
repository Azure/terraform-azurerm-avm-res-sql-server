mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  mock_resource "azurerm_mssql_elasticpool" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test/elasticPools/pool-test"
    }
  }
}

mock_provider "time" {}

variables {
  name             = "pool-test"
  location         = "eastus"
  enable_telemetry = false
  sql_server = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test"
  }
}

run "waits_only_during_destroy" {
  command = apply

  module {
    source = "./modules/elasticpool"
  }

  assert {
    condition     = time_sleep.wait_for_database_deletion.destroy_duration == "60s"
    error_message = "Pool deletion must allow 60 seconds for database membership cleanup."
  }

  assert {
    condition     = time_sleep.wait_for_database_deletion.create_duration == null
    error_message = "The database deletion grace period must not delay pool creation."
  }

  assert {
    condition     = output.resource_id == azurerm_mssql_elasticpool.this.id && output.name == azurerm_mssql_elasticpool.this.name && output.resource.id == azurerm_mssql_elasticpool.this.id
    error_message = "Pool outputs must retain their existing values."
  }
}
