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
  elastic_pools = {
    sample_pool = {
      sku = {
        name     = "StandardPool"
        capacity = 50
        tier     = "Standard"
      }
      per_database_settings = {
        min_capacity = 50
        max_capacity = 50
      }
      maintenance_configuration_name = "SQL_Default"
      zone_redundant                 = false
      license_type                   = "LicenseIncluded"
      max_size_gb                    = 50
    }
  }

  databases = {
    sample_database = {
      create_mode     = "Default"
      collation       = "SQL_Latin1_General_CP1_CI_AS"
      elastic_pool_id = module.sql_server.resource_elasticpools["sample_pool"].id
      license_type    = "LicenseIncluded"
      max_size_gb     = 50
      sku_name        = "ElasticPool"

      short_term_retention_policy = {
        retention_days           = 1
        backup_interval_in_hours = 24
      }
    }
  }
}

# This is the module call
module "sql_server" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  enable_telemetry             = var.enable_telemetry
  name                         = module.naming.sql_server.name_unique
  resource_group_name          = azurerm_resource_group.this.name
  administrator_login          = "mysqladmin"
  administrator_login_password = random_password.admin_password.result

  databases     = local.databases
  elastic_pools = local.elastic_pools
}
