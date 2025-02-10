terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.108"
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

resource "azurerm_mssql_server" "this" {
  location                     = azurerm_resource_group.this.location
  name                         = module.naming.sql_server.name_unique
  resource_group_name          = azurerm_resource_group.this.name
  version                      = "12.0"
  administrator_login          = "mysqladmin"
  administrator_login_password = random_password.admin_password.result
}

# This is the module call
module "sql_elastic_pool" {
  source = "../../modules/elasticpool"
  # source             = "Azure/avm-res-sql-server/azurerm//modules/elasticpool"

  name     = "my-elasticpool"
  location = azurerm_resource_group.this.location
  sql_server = {
    resource_id = azurerm_mssql_server.this.id
  }
}

module "sql_database" {
  source = "../../modules/database"
  # source             = "Azure/avm-res-sql-server/azurerm//modules/database"

  name = "my-database"
  sql_server = {
    resource_id = azurerm_mssql_server.this.id
  }
  elastic_pool_id = module.sql_elastic_pool.resource_id
  sku_name        = "ElasticPool"
}