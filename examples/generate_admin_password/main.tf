terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "AustraliaEast"
  name     = module.naming.resource_group.name_unique
}

data "azurerm_client_config" "current" {}

# Key Vault to store the auto-generated administrator password
resource "azurerm_key_vault" "this" {
  location                   = azurerm_resource_group.this.location
  name                       = module.naming.key_vault.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = false
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
}

# Allow the deploying principal to manage secrets in the Key Vault
resource "azurerm_role_assignment" "kv_secrets_officer" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
}

# Wait for RBAC propagation before the module tries to write the secret.
# Azure RBAC assignments can take up to 5 minutes to propagate globally.
resource "time_sleep" "rbac_propagation" {
  create_duration = "120s"

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}

# This is the module call.
# No administrator_login_password is provided — the module generates one automatically
# and stores it as a secret in the Key Vault above.
module "sql_server" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  server_version      = "12.0"
  administrator_login = "mysqladmin"
  administrator_login_password_key_vault_configuration = {
    key_vault_resource_id = azurerm_key_vault.this.id
    secret_name           = "sql-admin-password"
  }
  enable_telemetry                      = var.enable_telemetry
  generate_administrator_login_password = true
  name                                  = module.naming.sql_server.name_unique

  depends_on = [time_sleep.rbac_propagation]
}


