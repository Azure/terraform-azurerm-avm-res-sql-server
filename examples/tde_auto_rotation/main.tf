terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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

# Get current client configuration
data "azurerm_client_config" "current" {}

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

resource "random_password" "admin_password" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

# Create a user-assigned managed identity for the SQL Server
resource "azurerm_user_assigned_identity" "sql_identity" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.user_assigned_identity.name_unique}-sql"
  resource_group_name = azurerm_resource_group.this.name
}

# Create Key Vault for TDE keys
resource "azurerm_key_vault" "this" {
  location                   = azurerm_resource_group.this.location
  name                       = module.naming.key_vault.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  access_policy {
    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy",
      "Rotate",
    ]
    object_id = data.azurerm_client_config.current.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }
  # Grant SQL Server identity access to Key Vault
  access_policy {
    key_permissions = [
      "Get",
      "WrapKey",
      "UnwrapKey",
    ]
    object_id = azurerm_user_assigned_identity.sql_identity.principal_id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }
}

# Create a key in Key Vault for TDE
resource "azurerm_key_vault_key" "tde_key" {
  key_opts = [
    "unwrapKey",
    "wrapKey",
  ]
  key_type     = "RSA"
  key_vault_id = azurerm_key_vault.this.id
  name         = "tde-key"
  key_size     = 2048

  # Optional: Configure automatic key rotation in Key Vault
  rotation_policy {
    expire_after         = "P90D"
    notify_before_expiry = "P29D"

    automatic {
      time_before_expiry = "P30D"
    }
  }
}

# This is the module call with TDE auto-rotation enabled
module "sql_server" {
  source = "../../"

  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  server_version               = "12.0"
  administrator_login          = "mysqladmin"
  administrator_login_password = random_password.admin_password.result
  # Enable TDE with customer-managed key and auto-rotation
  enable_telemetry = var.enable_telemetry
  # Configure managed identity for SQL Server
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.sql_identity.id]
  }
  name                                                         = module.naming.sql_server.name_unique
  primary_user_assigned_identity_id                            = azurerm_user_assigned_identity.sql_identity.id
  enable_transparent_data_encryption_with_customer_managed_key = true
  transparent_data_encryption_key_automatic_rotation_enabled   = true
  transparent_data_encryption_key_vault_key_id                 = azurerm_key_vault_key.tde_key.id

  depends_on = [
    azurerm_key_vault_key.tde_key,
    azurerm_key_vault.this
  ]
}
