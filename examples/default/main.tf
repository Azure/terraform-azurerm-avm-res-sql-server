terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.108"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
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
  location = "AustraliaEast"
  name     = module.naming.resource_group.name_unique
}

resource "random_password" "admin_password" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
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
  location                     = azurerm_resource_group.this.location
  server_version               = "12.0"
}
