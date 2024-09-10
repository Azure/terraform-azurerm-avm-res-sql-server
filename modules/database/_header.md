# Azure SQL Database Module

This module is used to create Azure SQL Databases.

## Features

This module supports managing Azure SQL Databases.

The module supports:

- Creating a new database
- Optionally adding to an elastic pool

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Database

This example shows the basic usage of the module. It creates a new database.

```terraform
module "avm-res-sql-server-database" {
  source = "Azure/avm-res-sql-server/azurerm//modules/database"

  sql_server = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Sql/servers/mySqlServer"
  }
  name = "my-database"
}
```
