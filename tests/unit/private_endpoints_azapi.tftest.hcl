mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateEndpoints/pep-sql-test"
      output = {
        properties = {
          customDnsConfigs  = []
          networkInterfaces = [{ id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkInterfaces/nic" }]
        }
      }
    }
  }
  mock_data "azapi_resource" {
    defaults = {
      output = {
        private_ip_address = "10.0.0.9"
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
}

mock_provider "random" {}

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

run "body_reproduces_the_azurerm_request" {
  command = apply

  variables {
    tags = { server = "only" }
    private_endpoints = {
      primary = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net"]
        application_security_group_associations = {
          web = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/applicationSecurityGroups/web"
        }
        ip_configurations = {
          static = {
            name               = "ipconfig"
            private_ip_address = "10.0.0.4"
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.private_endpoints["primary"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test" && azapi_resource.private_endpoints["primary"].name == "pep-sql-test" && azapi_resource.private_endpoints["primary"].type == "Microsoft.Network/privateEndpoints@2024-05-01"
    error_message = "The private endpoint MUST default to the server resource group and the pep-<name> name."
  }

  assert {
    condition     = length(coalesce(azapi_resource.private_endpoints["primary"].tags, {})) == 0
    error_message = "Private endpoints MUST NOT inherit the server tags, as before."
  }

  assert {
    condition     = jsonencode(azapi_resource.private_endpoints["primary"].body.properties.ipConfigurations) == jsonencode([{ name = "ipconfig", properties = { groupId = "sqlServer", memberName = "sqlServer", privateIPAddress = "10.0.0.4" } }])
    error_message = "IP configurations MUST default the group and member to sqlServer."
  }

  assert {
    condition     = jsonencode(azapi_resource.private_endpoints["primary"].body.properties.applicationSecurityGroups) == jsonencode([{ id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/applicationSecurityGroups/web" }]) && !contains(keys(azapi_resource.private_endpoints["primary"].body.properties), "customNetworkInterfaceName")
    error_message = "Application security groups MUST be in the body, and an unset custom NIC name MUST NOT be sent."
  }

  assert {
    condition     = azapi_resource.private_endpoints["primary"].body.properties.privateLinkServiceConnections[0].properties.privateLinkServiceId == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Sql/servers/sql-test"
    error_message = "The private link connection MUST target the server."
  }

  assert {
    condition     = azapi_resource.private_dns_zone_groups["primary"].name == "default" && jsonencode(azapi_resource.private_dns_zone_groups["primary"].body.properties.privateDnsZoneConfigs) == jsonencode([{ name = "privatelink.database.windows.net", properties = { privateDnsZoneId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net" } }])
    error_message = "The DNS zone group MUST keep the azurerm name and name each configuration after its zone."
  }

  assert {
    condition     = output.private_endpoints["primary"].private_service_connection[0].private_ip_address == "10.0.0.9"
    error_message = "The private IP address MUST be read from the network interface."
  }
}

run "no_dns_zone_group_without_zones" {
  command = apply

  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
      }
    }
  }

  assert {
    condition     = length(azapi_resource.private_dns_zone_groups) == 0 && jsonencode(azapi_resource.private_endpoints["primary"].body.properties.applicationSecurityGroups) == "[]"
    error_message = "No DNS zone group MUST be created without zones, and an empty application security group list MUST be sent."
  }
}
