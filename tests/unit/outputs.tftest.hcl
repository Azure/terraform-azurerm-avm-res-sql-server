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
      id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-outputs-test/providers/Microsoft.Sql/servers/sql-outputs-test"
      fully_qualified_domain_name = "sql-outputs-test.database.windows.net"
    }
  }
}

mock_provider "random" {}

mock_provider "time" {}

variables {
  name                = "sql-outputs-test"
  location            = "eastus"
  resource_group_name = "rg-outputs-test"
  server_version      = "12.0"
  enable_telemetry    = false
  azuread_administrator = {
    login_username              = "mock-administrator"
    object_id                   = "00000000-0000-0000-0000-000000000001"
    azuread_authentication_only = true
  }
}

run "resource_fqdn_is_discrete_and_not_sensitive" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }

  assert {
    condition     = output.resource_fqdn == azurerm_mssql_server.this.fully_qualified_domain_name
    error_message = "resource_fqdn must expose the server fully qualified domain name."
  }
  assert {
    condition     = !issensitive(output.resource_fqdn)
    error_message = "resource_fqdn must not be marked sensitive."
  }
}
