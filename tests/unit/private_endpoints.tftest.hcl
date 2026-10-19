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
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-endpoint-test/providers/Microsoft.Sql/servers/sql-endpoint-test"
    }
  }
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-endpoint-test/providers/Microsoft.Network/privateEndpoints/pe-test"
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
  name                = "sql-endpoint-test"
  location            = "eastus"
  resource_group_name = "rg-endpoint-test"
  server_version      = "12.0"
  enable_telemetry    = false
  azuread_administrator = {
    login_username              = "mock-administrator"
    object_id                   = "00000000-0000-0000-0000-000000000001"
    azuread_authentication_only = true
  }
}

run "no_endpoints_by_default" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }

  assert {
    condition     = length(output.private_endpoints) == 0 && length(azapi_resource.private_endpoint_locks) == 0 && length(azapi_resource.private_endpoint_role_assignments) == 0
    error_message = "Private endpoint resources must remain opt-in."
  }
  assert {
    condition     = length(data.azapi_resource_list.private_endpoint_role_definitions) == 0 && length(random_uuid.private_endpoint_role_assignment_name) == 0
    error_message = "No role lookup or assignment UUID is needed without private endpoint roles."
  }
}

run "managed_defaults_preserve_names_and_addresses" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
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
    condition     = toset(keys(azurerm_private_endpoint.this)) == toset(["primary"]) && length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0
    error_message = "Managed endpoints must retain their original resource address."
  }
  assert {
    condition     = output.private_endpoints["primary"].name == "pep-sql-endpoint-test" && one(output.private_endpoints["primary"].private_service_connection).name == "pse-sql-endpoint-test"
    error_message = "Omitted endpoint and connection names must retain the existing defaults."
  }
  assert {
    condition     = toset(one(output.private_endpoints["primary"].private_service_connection).subresource_names) == toset(["sqlServer"]) && one(output.private_endpoints["primary"].ip_configuration).subresource_name == "sqlServer" && one(output.private_endpoints["primary"].ip_configuration).member_name == "sqlServer"
    error_message = "Omitted subresource and IP member names must continue to target sqlServer."
  }
  assert {
    condition     = length(azapi_resource.private_endpoint_locks) == 0 && length(azapi_resource.private_endpoint_role_assignments) == 0
    error_message = "Existing callers without locks or roles must not acquire endpoint extensions."
  }
}

run "managed_settings_are_applied" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        name                            = "custom-endpoint"
        location                        = "westus2"
        resource_group_name             = "rg-endpoint-override"
        network_interface_name          = "custom-nic"
        private_service_connection_name = "custom-connection"
        subresource_name                = "custom-service"
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        private_dns_zone_group_name     = "custom-dns"
        private_dns_zone_resource_ids   = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net"]
        tags                            = { owner = "endpoint" }
        application_security_group_associations = {
          web = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/applicationSecurityGroups/web"
        }
        ip_configurations = {
          static = {
            name               = "custom-ipconfig"
            private_ip_address = "10.0.0.5"
            member_name        = "custom-member"
          }
        }
        lock = {
          kind  = "ReadOnly"
          name  = "custom-lock"
          notes = "Endpoint lock notes"
        }
        role_assignments = {
          reader = {
            name                                   = "11111111-1111-1111-1111-111111111111"
            role_definition_id_or_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            principal_id                           = "22222222-2222-2222-2222-222222222222"
            description                            = "Endpoint reader"
            principal_type                         = "ServicePrincipal"
            skip_service_principal_aad_check       = true
            condition                              = "!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})"
            condition_version                      = "2.0"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-identity/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
          }
        }
      }
    }
  }

  assert {
    condition     = output.private_endpoints["primary"].name == "custom-endpoint" && output.private_endpoints["primary"].location == "westus2" && output.private_endpoints["primary"].resource_group_name == "rg-endpoint-override" && output.private_endpoints["primary"].custom_network_interface_name == "custom-nic" && output.private_endpoints["primary"].tags["owner"] == "endpoint"
    error_message = "Endpoint name, location, resource group name, NIC name and tags must be honored."
  }
  assert {
    condition     = one(output.private_endpoints["primary"].private_service_connection).name == "custom-connection" && toset(one(output.private_endpoints["primary"].private_service_connection).subresource_names) == toset(["custom-service"]) && one(output.private_endpoints["primary"].ip_configuration).subresource_name == "custom-service" && one(output.private_endpoints["primary"].ip_configuration).member_name == "custom-member" && one(output.private_endpoints["primary"].ip_configuration).private_ip_address == "10.0.0.5"
    error_message = "Connection and IP configuration overrides must not be replaced by hardcoded defaults."
  }
  assert {
    condition     = one(output.private_endpoints["primary"].private_dns_zone_group).name == "custom-dns" && toset(one(output.private_endpoints["primary"].private_dns_zone_group).private_dns_zone_ids) == var.private_endpoints["primary"].private_dns_zone_resource_ids
    error_message = "Managed DNS settings must remain attached to the endpoint."
  }
  assert {
    condition     = azurerm_private_endpoint_application_security_group_association.this["primary-web"].private_endpoint_id == output.private_endpoints["primary"].id
    error_message = "Managed application security group associations must retain the original address and endpoint scope."
  }
  assert {
    condition     = azapi_resource.private_endpoint_locks["primary"].parent_id == output.private_endpoints["primary"].id && azapi_resource.private_endpoint_locks["primary"].name == "custom-lock" && azapi_resource.private_endpoint_locks["primary"].body.properties.level == "ReadOnly" && azapi_resource.private_endpoint_locks["primary"].body.properties.notes == "Endpoint lock notes"
    error_message = "Endpoint lock name, level, notes and scope must be configured on a real resource."
  }
  assert {
    condition = alltrue([
      for assignment in azapi_resource.private_endpoint_role_assignments :
      assignment.parent_id == output.private_endpoints["primary"].id &&
      assignment.name == "11111111-1111-1111-1111-111111111111" &&
      assignment.body.properties.principalId == var.private_endpoints["primary"].role_assignments["reader"].principal_id &&
      assignment.body.properties.roleDefinitionId == var.private_endpoints["primary"].role_assignments["reader"].role_definition_id_or_name &&
      assignment.body.properties.description == "Endpoint reader" &&
      assignment.body.properties.principalType == "ServicePrincipal" &&
      assignment.body.properties.condition == var.private_endpoints["primary"].role_assignments["reader"].condition &&
      assignment.body.properties.conditionVersion == "2.0" &&
      assignment.body.properties.delegatedManagedIdentityResourceId == var.private_endpoints["primary"].role_assignments["reader"].delegated_managed_identity_resource_id
    ]) && length(azapi_resource.private_endpoint_role_assignments) == 1
    error_message = "All endpoint role assignment fields must be applied at the endpoint scope."
  }
  assert {
    condition     = data.azapi_resource_list.private_endpoint_role_definitions["primary"].parent_id == output.private_endpoints["primary"].id && length(random_uuid.private_endpoint_role_assignment_name) == 1 && alltrue([for assignment in azapi_resource.private_endpoint_role_assignments : assignment.name != "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"])
    error_message = "Role lookups must use the endpoint scope and explicit assignment names must take precedence over generated UUIDs."
  }
}

run "unmanaged_dns_extensions_and_associations" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      primary = {
        name                            = "unmanaged-endpoint"
        private_service_connection_name = "unmanaged-connection"
        subresource_name                = "custom-service"
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        application_security_group_associations = {
          web = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/applicationSecurityGroups/web"
        }
        ip_configurations = {
          static = {
            name               = "unmanaged-ipconfig"
            private_ip_address = "10.0.0.6"
            member_name        = "unmanaged-member"
          }
        }
        lock = {
          kind  = "CanNotDelete"
          notes = "Unmanaged DNS endpoint"
        }
        role_assignments = {
          reader = {
            name                       = "33333333-3333-3333-3333-333333333333"
            principal_id               = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            principal_type             = "User"
          }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_private_endpoint.this) == 0 && toset(keys(azurerm_private_endpoint.this_unmanaged_dns_zone_groups)) == toset(["primary"]) && output.private_endpoints["primary"].name == "unmanaged-endpoint"
    error_message = "Externally managed DNS must retain the unmanaged endpoint resource address and output."
  }
  assert {
    condition     = one(output.private_endpoints["primary"].private_service_connection).name == "unmanaged-connection" && toset(one(output.private_endpoints["primary"].private_service_connection).subresource_names) == toset(["custom-service"]) && one(output.private_endpoints["primary"].ip_configuration).member_name == "unmanaged-member" && one(output.private_endpoints["primary"].ip_configuration).subresource_name == "custom-service"
    error_message = "Unmanaged endpoints must honor connection and IP member overrides."
  }
  assert {
    condition     = azurerm_private_endpoint_application_security_group_association.this["primary-web"].private_endpoint_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["primary"].id
    error_message = "Unmanaged application security group associations must use the unmanaged endpoint, not an empty managed collection."
  }
  assert {
    condition     = azapi_resource.private_endpoint_locks["primary"].parent_id == output.private_endpoints["primary"].id && azapi_resource.private_endpoint_locks["primary"].name == "lock-CanNotDelete" && azapi_resource.private_endpoint_locks["primary"].body.properties.notes == "Unmanaged DNS endpoint"
    error_message = "Locks must be applied when DNS is managed externally."
  }
  assert {
    condition     = length(azapi_resource.private_endpoint_role_assignments) == 1 && alltrue([for assignment in azapi_resource.private_endpoint_role_assignments : assignment.parent_id == output.private_endpoints["primary"].id && assignment.name == "33333333-3333-3333-3333-333333333333" && assignment.body.properties.principalType == "User"])
    error_message = "Role assignments must be applied when DNS is managed externally."
  }
}

run "role_names_and_generated_assignment_names" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        role_assignments = {
          reader = {
            role_definition_id_or_name       = "rEaDeR"
            principal_id                     = "22222222-2222-2222-2222-222222222222"
            skip_service_principal_aad_check = true
          }
        }
      }
    }
  }

  assert {
    condition     = length(data.azapi_resource_list.private_endpoint_role_definitions) == 1 && data.azapi_resource_list.private_endpoint_role_definitions["primary"].parent_id == output.private_endpoints["primary"].id
    error_message = "Role names must be looked up at the actual endpoint scope."
  }
  assert {
    condition     = length(random_uuid.private_endpoint_role_assignment_name) == 1 && alltrue([for assignment in azapi_resource.private_endpoint_role_assignments : assignment.name == "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee" && assignment.body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" && assignment.body.properties.principalType == "ServicePrincipal"])
    error_message = "Role names must resolve case-insensitively and omitted assignment names must use a persisted UUID; the skip flag must select ServicePrincipal."
  }
}

run "locks_inherit_override_and_opt_out" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    lock = {
      kind = "CanNotDelete"
      name = "server-lock"
    }
    private_endpoints = {
      inherited = {
        name               = "inherited-endpoint"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
      }
      overridden = {
        name               = "overridden-endpoint"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        lock = {
          kind  = "ReadOnly"
          notes = "Endpoint override"
        }
      }
      unlocked = {
        name               = "unlocked-endpoint"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        lock               = { kind = "None" }
      }
    }
  }

  assert {
    condition     = toset(keys(azapi_resource.private_endpoint_locks)) == toset(["inherited", "overridden"])
    error_message = "An endpoint must inherit the server lock unless overridden or opted out with None."
  }
  assert {
    condition     = azapi_resource.private_endpoint_locks["inherited"].name == "server-lock" && azapi_resource.private_endpoint_locks["inherited"].body.properties.level == "CanNotDelete" && azapi_resource.private_endpoint_locks["overridden"].name == "lock-ReadOnly" && azapi_resource.private_endpoint_locks["overridden"].body.properties.notes == "Endpoint override"
    error_message = "Inherited and endpoint-specific lock values must remain independent."
  }
}

run "role_keys_and_scopes_do_not_collide" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      a-b = {
        name               = "first-endpoint"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        role_assignments = {
          c = {
            principal_id               = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          }
        }
      }
      a = {
        name               = "second-endpoint"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        role_assignments = {
          b-c = {
            principal_id               = "44444444-4444-4444-4444-444444444444"
            role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          }
        }
      }
    }
  }
  override_resource {
    target = azurerm_private_endpoint.this["a-b"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-endpoint-test/providers/Microsoft.Network/privateEndpoints/first-endpoint"
    }
  }
  override_resource {
    target = azurerm_private_endpoint.this["a"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-endpoint-test/providers/Microsoft.Network/privateEndpoints/second-endpoint"
    }
  }

  assert {
    condition     = length(azapi_resource.private_endpoint_role_assignments) == 2 && azapi_resource.private_endpoint_role_assignments[jsonencode(["a-b", "c"])].parent_id == output.private_endpoints["a-b"].id && azapi_resource.private_endpoint_role_assignments[jsonencode(["a", "b-c"])].parent_id == output.private_endpoints["a"].id
    error_message = "Endpoint and role keys containing hyphens must not collide or attach to another endpoint."
  }
}

run "azapi_controls_are_forwarded" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    resource_types = {
      authorization_locks            = "Microsoft.Authorization/locks@2016-09-01"
      authorization_role_assignments = "Microsoft.Authorization/roleAssignments@2020-10-01-preview"
    }
    retry = {
      error_message_regex  = ["ScopeLocked"]
      interval_seconds     = 10
      max_interval_seconds = 30
    }
    timeouts = {
      create = "10m"
      read   = "5m"
      update = "10m"
      delete = "15m"
    }
    ignore_body_changes = {
      authorization_locks            = ["properties.notes"]
      authorization_role_assignments = ["properties.description"]
    }
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        lock               = { kind = "ReadOnly" }
        role_assignments = {
          reader = {
            principal_id               = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.private_endpoint_locks["primary"].type == var.resource_types.authorization_locks && alltrue([for assignment in azapi_resource.private_endpoint_role_assignments : assignment.type == var.resource_types.authorization_role_assignments])
    error_message = "The endpoint extension API versions must be consumer configurable."
  }
  assert {
    condition     = azapi_resource.private_endpoint_locks["primary"].retry.error_message_regex == var.retry.error_message_regex && azapi_resource.private_endpoint_locks["primary"].retry.interval_seconds == 10 && azapi_resource.private_endpoint_locks["primary"].retry.max_interval_seconds == 30 && alltrue([for assignment in azapi_resource.private_endpoint_role_assignments : assignment.retry.error_message_regex == var.retry.error_message_regex && assignment.retry.interval_seconds == 10 && assignment.retry.max_interval_seconds == 30])
    error_message = "Retry configuration must reach both endpoint extension resource types."
  }
  assert {
    condition     = azapi_resource.private_endpoint_locks["primary"].timeouts == var.timeouts && alltrue([for assignment in azapi_resource.private_endpoint_role_assignments : assignment.timeouts == var.timeouts])
    error_message = "All create, read, update and delete timeouts must reach both endpoint extension resource types."
  }
}

run "invalid_subnet_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = { primary = { subnet_resource_id = "not-a-subnet" } }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_dns_zone_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        private_dns_zone_resource_ids = ["not-a-dns-zone"]
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_application_security_group_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        application_security_group_associations = { web = "not-an-asg" }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_delegated_identity_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        role_assignments = {
          reader = {
            principal_id                           = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name             = "Reader"
            delegated_managed_identity_resource_id = "not-an-identity"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_lock_kind_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        lock               = { kind = "invalid" }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_role_assignment_name_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        role_assignments = {
          reader = {
            name                       = "not-a-guid"
            principal_id               = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name = "Reader"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "skip_aad_check_rejects_non_service_principals" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        role_assignments = {
          reader = {
            principal_id                     = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name       = "Reader"
            principal_type                   = "User"
            skip_service_principal_aad_check = true
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_condition_version_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        role_assignments = {
          reader = {
            principal_id               = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name = "Reader"
            condition                  = "!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})"
            condition_version          = "1.0"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "unknown_role_name_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm

    random = random
    time   = time
  }
  variables {
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default"
        role_assignments = {
          reader = {
            principal_id               = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name = "Role that does not exist"
          }
        }
      }
    }
  }
  expect_failures = [azapi_resource.private_endpoint_role_assignments]
}
