terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see<https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = "AustraliaEast"
}

resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  databases = {
    my_db = {
      create_mode  = "Default"
      collation    = "SQL_Latin1_General_CP1_CI_AS"
      server_id    = module.sql_server.resource.id
      license_type = "LicenseIncluded"
      max_size_gb  = 50
      sku_name     = "S0"

      short_term_retention_policy = {
        retention_days           = 1
        backup_interval_in_hours = 24
      }
    }
  }
}

resource "azurerm_mssql_server" "this" {
  name                         = module.naming.sql_server.name_unique
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  version                      = "12.0"
  administrator_login          = "mysqladmin"
  administrator_login_password = random_password.admin_password.result
}

# This is the module call
module "sql_server" {
  source = "../../"
  # source             = "Azure/avm-res-sql-server/azurerm"

  enable_telemetry             = var.enable_telemetry
  existing_parent_resource     = { name = azurerm_mssql_server.this.name }
  resource_group_name          = azurerm_resource_group.this.name
  administrator_login          = "mysqladmin"
  administrator_login_password = random_password.admin_password.result

  databases = local.databases
}
