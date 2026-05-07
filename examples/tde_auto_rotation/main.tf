terraform {
  required_version = ">= 1.9, ~> 1.10"

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

resource "random_password" "admin_password" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

resource "random_string" "kv_suffix" {
  length  = 4
  lower   = true
  numeric = true
  special = false
  upper   = false
}

# User-assigned managed identity for SQL Server CMK TDE
resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# Key Vault for CMK TDE
resource "azurerm_key_vault" "this" {
  location                   = azurerm_resource_group.this.location
  name                       = "${module.naming.key_vault.name_unique}${random_string.kv_suffix.result}"
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = true
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
}

# Grant the deploying principal permissions to create the key
resource "azurerm_role_assignment" "kv_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
}

# Grant the SQL Server managed identity permission to use the key for TDE
resource "azurerm_role_assignment" "sql_kv_crypto" {
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
}

# Key Vault Key with rotation policy for CMK TDE
resource "azurerm_key_vault_key" "tde" {
  key_opts = [
    "unwrapKey",
    "wrapKey",
  ]
  key_type     = "RSA"
  key_vault_id = azurerm_key_vault.this.id
  name         = "tde-key"
  key_size     = 2048

  rotation_policy {
    expire_after         = "P90D"
    notify_before_expiry = "P29D"

    automatic {
      time_before_expiry = "P30D"
    }
  }

  depends_on = [azurerm_role_assignment.kv_admin]
}

locals {
  databases = {
    tde_db = {
      name                                                       = "tde-auto-rotation-db"
      sku_name                                                   = "S0"
      max_size_gb                                                = 2
      transparent_data_encryption_enabled                        = true
      transparent_data_encryption_key_automatic_rotation_enabled = true
      transparent_data_encryption_key_vault_key_id               = azurerm_key_vault_key.tde.id
      managed_identities = {
        user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
      }
    }
  }
}

# This is the module call
module "sql_server" {
  source = "../../"

  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  server_version               = "12.0"
  administrator_login          = "mysqladmin"
  administrator_login_password = random_password.admin_password.result
  databases                    = local.databases
  enable_telemetry             = var.enable_telemetry
  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }
  name                                         = module.naming.sql_server.name_unique
  primary_user_assigned_identity_id            = azurerm_user_assigned_identity.this.id
  transparent_data_encryption_key_vault_key_id = azurerm_key_vault_key.tde.id

  depends_on = [azurerm_role_assignment.sql_kv_crypto]
}
