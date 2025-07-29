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
  features {}
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

resource "random_password" "admin_password" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

locals {
  databases = {
    my_sample_db = {
      name         = "my_sample_db"
      create_mode  = "Default"
      collation    = "SQL_Latin1_General_CP1_CI_AS"
      license_type = "LicenseIncluded"
      max_size_gb  = 50
      sku_name     = "S0"

      short_term_retention_policy = {
        retention_days           = 1
        backup_interval_in_hours = 24
      }

      long_term_retention_policy = {
        weekly_retention  = "P2W1D"
        monthly_retention = "P2M"
        yearly_retention  = "P1Y"
        week_of_year      = 1
      }

      tags = local.tags
    }
  }
  tags = {
    environment = "sample"
    cost_centre = "demo"
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
  name                         = module.naming.sql_server.name_unique
  tags                         = local.tags
}
