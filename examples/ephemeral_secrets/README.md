# SQL Server with Ephemeral Secrets Example

This example demonstrates how to use the ephemeral secrets feature with write-only passwords for enhanced security.

<!-- BEGIN_TF_DOCS -->
## Example Usage

```hcl
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

# Example using ephemeral secrets for enhanced security
module "sql_server" {
  source = "../../"

  location                                = azurerm_resource_group.this.location
  resource_group_name                     = azurerm_resource_group.this.name
  server_version                          = "12.0"
  administrator_login                     = "mysqladmin"
  # Using ephemeral secrets instead of administrator_login_password
  administrator_login_password_wo         = random_password.admin_password.result
  administrator_login_password_wo_version = "v1.0"

  enable_telemetry = var.enable_telemetry
  name            = module.naming.sql_server.name_unique
  tags            = local.tags
}
```

This example shows how to use the new ephemeral secrets feature where:
- `administrator_login_password_wo` provides the password in write-only mode
- `administrator_login_password_wo_version` tracks the password version for rotation purposes
- The password is never stored in the Terraform state file

## Benefits of Ephemeral Secrets

1. **Enhanced Security**: Passwords are never stored in Terraform state files
2. **Compliance**: Meets enterprise security requirements for credential management
3. **Rotation Support**: Version tracking enables automated password rotation
4. **Backward Compatibility**: Existing `administrator_login_password` usage remains unchanged

<!-- END_TF_DOCS -->
