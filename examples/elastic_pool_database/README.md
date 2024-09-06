<!-- BEGIN_TF_DOCS -->
# SQL Elastic Pool with database

This illustrates how to deploy a database on an Elastic SQL Pool.

```hcl
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (3.5.1)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="provider_random"></a> [random](#provider\_random) (3.5.1)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_password.admin_password](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/password) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see<https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

### <a name="module_sql_server"></a> [sql\_server](#module\_sql\_server)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->