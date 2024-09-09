<!-- BEGIN_TF_DOCS -->
# Azure SQL Elastic Pool Module

This module is used to create Azure SQL Elastic Pools.

## Features

This module supports managing Azure SQL Pools.

The module supports:

- Creating a new elastic pool

## Usage

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

### Example - Basic Database

This example shows the basic usage of the module. It creates a new database.

```terraform
module "avm-res-sql-server-elasticpool" {
  source = "Azure/avm-res-sql-server/azurerm//modules/elasticpool"

  sql_server = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroupHub/providers/Microsoft.Network/virtualNetworks/myVNetRemote"
  }
  name = "my-elasticpool"
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.108)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azurerm_mssql_elasticpool.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_elasticpool) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: The location of the elastic pool.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the elastic pool.

Type: `string`

### <a name="input_sql_server"></a> [sql\_server](#input\_sql\_server)

Description: The resource ID of the SQL Server to create the elastic pool on.

Type:

```hcl
object({
    resource_id = string
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_license_type"></a> [license\_type](#input\_license\_type)

Description: The license type for the elastic pool.

Type: `string`

Default: `"LicenseIncluded"`

### <a name="input_maintenance_configuration_name"></a> [maintenance\_configuration\_name](#input\_maintenance\_configuration\_name)

Description: The name of the maintenance configuration.

Type: `string`

Default: `"SQL_Default"`

### <a name="input_max_size_bytes"></a> [max\_size\_bytes](#input\_max\_size\_bytes)

Description: The maximum size of the elastic pool in bytes.

Type: `number`

Default: `null`

### <a name="input_max_size_gb"></a> [max\_size\_gb](#input\_max\_size\_gb)

Description: The maximum size of the elastic pool in GB.

Type: `number`

Default: `null`

### <a name="input_per_database_settings"></a> [per\_database\_settings](#input\_per\_database\_settings)

Description: The per-database settings for the elastic pool.

Type:

```hcl
object({
    min_capacity = number
    max_capacity = number
  })
```

Default:

```json
{
  "max_capacity": 10,
  "min_capacity": 0
}
```

### <a name="input_sku"></a> [sku](#input\_sku)

Description: The SKU details for the elastic pool.

Type:

```hcl
object({
    name     = string
    capacity = number
    tier     = string
    family   = optional(string)
  })
```

Default:

```json
{
  "capacity": 50,
  "family": "Gen5",
  "name": "PremiumPool",
  "tier": "Premium"
}
```

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_zone_redundant"></a> [zone\_redundant](#input\_zone\_redundant)

Description: Specifies if the elastic pool is zone redundant.

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the elastic pool.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The elastic pool.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ID of the elastic pool.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->