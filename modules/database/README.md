<!-- BEGIN_TF_DOCS -->
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
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroupHub/providers/Microsoft.Network/virtualNetworks/myVNetRemote"
  }
  name = "my-database"
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

- [azurerm_mssql_database.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the database.

Type: `string`

### <a name="input_sql_server"></a> [sql\_server](#input\_sql\_server)

Description: The resource ID of the SQL Server to create the database on.

Type:

```hcl
object({
    resource_id = string
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_auto_pause_delay_in_minutes"></a> [auto\_pause\_delay\_in\_minutes](#input\_auto\_pause\_delay\_in\_minutes)

Description: The time in minutes before the database is automatically paused.

Type: `number`

Default: `null`

### <a name="input_collation"></a> [collation](#input\_collation)

Description: The collation of the database.

Type: `string`

Default: `null`

### <a name="input_create_mode"></a> [create\_mode](#input\_create\_mode)

Description: The mode to create the database.

Type: `string`

Default: `"Default"`

### <a name="input_elastic_pool_id"></a> [elastic\_pool\_id](#input\_elastic\_pool\_id)

Description: The ID of the elastic pool containing the database.

Type: `string`

Default: `null`

### <a name="input_geo_backup_enabled"></a> [geo\_backup\_enabled](#input\_geo\_backup\_enabled)

Description: Whether geo-backup is enabled for the database.

Type: `bool`

Default: `true`

### <a name="input_import"></a> [import](#input\_import)

Description: The import configuration for the database.

Type:

```hcl
object({
    storage_uri            = string
    storage_key            = string
    storage_key_type       = string
    administrator_login    = string
    administrator_password = string
    authentication_type    = string
    storage_account_id     = string
  })
```

Default: `null`

### <a name="input_ledger_enabled"></a> [ledger\_enabled](#input\_ledger\_enabled)

Description: Whether ledger is enabled for the database.

Type: `bool`

Default: `false`

### <a name="input_license_type"></a> [license\_type](#input\_license\_type)

Description: The license type for the database.

Type: `string`

Default: `null`

### <a name="input_long_term_retention_policy"></a> [long\_term\_retention\_policy](#input\_long\_term\_retention\_policy)

Description: The long-term retention policy for the database.

Type:

```hcl
object({
    weekly_retention  = string
    monthly_retention = string
    yearly_retention  = string
    week_of_year      = number
  })
```

Default: `null`

### <a name="input_maintenance_configuration_name"></a> [maintenance\_configuration\_name](#input\_maintenance\_configuration\_name)

Description: The name of the maintenance configuration.

Type: `string`

Default: `null`

### <a name="input_max_size_gb"></a> [max\_size\_gb](#input\_max\_size\_gb)

Description: The maximum size of the database in gigabytes.

Type: `number`

Default: `null`

### <a name="input_min_capacity"></a> [min\_capacity](#input\_min\_capacity)

Description: The minimum capacity of the database.

Type: `number`

Default: `null`

### <a name="input_read_replica_count"></a> [read\_replica\_count](#input\_read\_replica\_count)

Description: The number of read replicas for the database.

Type: `number`

Default: `null`

### <a name="input_read_scale"></a> [read\_scale](#input\_read\_scale)

Description: Whether read scale is enabled for the database.

Type: `bool`

Default: `null`

### <a name="input_recover_database_id"></a> [recover\_database\_id](#input\_recover\_database\_id)

Description: The ID of the database to recover.

Type: `string`

Default: `null`

### <a name="input_restore_dropped_database_id"></a> [restore\_dropped\_database\_id](#input\_restore\_dropped\_database\_id)

Description: The ID of the dropped database to restore.

Type: `string`

Default: `null`

### <a name="input_restore_point_in_time"></a> [restore\_point\_in\_time](#input\_restore\_point\_in\_time)

Description: The point in time to restore the database to.

Type: `string`

Default: `null`

### <a name="input_sample_name"></a> [sample\_name](#input\_sample\_name)

Description: The name of the sample database.

Type: `string`

Default: `null`

### <a name="input_short_term_retention_policy"></a> [short\_term\_retention\_policy](#input\_short\_term\_retention\_policy)

Description: The short-term retention policy for the database.

Type:

```hcl
object({
    retention_days           = number
    backup_interval_in_hours = number
  })
```

Default:

```json
{
  "backup_interval_in_hours": 12
}
```

### <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name)

Description: The SKU name for the database.

Type: `string`

Default: `null`

### <a name="input_storage_account_type"></a> [storage\_account\_type](#input\_storage\_account\_type)

Description: The type of storage account for the database.

Type: `string`

Default: `"Geo"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_threat_detection_policy"></a> [threat\_detection\_policy](#input\_threat\_detection\_policy)

Description: The threat detection policy for the database.

Type:

```hcl
object({
    state                      = string
    disabled_alerts            = list(string)
    email_account_admins       = string
    email_addresses            = list(string)
    retention_days             = number
    storage_account_access_key = string
    storage_endpoint           = string
  })
```

Default:

```json
{
  "email_account_admins": "Disabled",
  "state": "Disabled"
}
```

### <a name="input_transparent_data_encryption_enabled"></a> [transparent\_data\_encryption\_enabled](#input\_transparent\_data\_encryption\_enabled)

Description: Whether transparent data encryption is enabled for the database.

Type: `bool`

Default: `true`

### <a name="input_zone_redundant"></a> [zone\_redundant](#input\_zone\_redundant)

Description: Whether the database is zone redundant.

Type: `bool`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the SQL database.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The full resource object of the SQL database.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource ID of the SQL database.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->