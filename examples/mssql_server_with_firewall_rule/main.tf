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

# This is the module call
module "sql_server_with_firewall" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  enable_telemetry              = var.enable_telemetry
  name                          = module.naming.sql_server.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  administrator_login           = "mssqladmin"
  administrator_login_password  = random_password.admin_password.result
  public_network_access_enabled = true
  firewall_rules = {
    single_ip = {
      start_ip_address = "40.112.8.12"
      end_ip_address   = "40.112.8.12"
    }
    ip_range = {
      start_ip_address = "40.112.0.0"
      end_ip_address   = "40.112.255.255"
    }
    access_azure = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }
}
