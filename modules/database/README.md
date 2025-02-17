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
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Sql/servers/mySqlServer"
  }
  name = "my-database"
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_mssql_database.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)

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

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_elastic_pool_id"></a> [elastic\_pool\_id](#input\_elastic\_pool\_id)

Description: The ID of the elastic pool containing the database.

Type: `string`

Default: `null`

### <a name="input_geo_backup_enabled"></a> [geo\_backup\_enabled](#input\_geo\_backup\_enabled)

Description: Whether geo-backup is enabled for the database.

Type: `bool`

Default: `true`

### <a name="input_import"></a> [import](#input\_import)

Description: Controls the Import configuration on this resource. The following properties can be specified:

- `storage_uri` - (Required) Specifies the URI of the storage account to import the database from.
- `storage_key` - (Required) Specifies the key of the storage account to import the database from.
- `storage_key_type` - (Required) Specifies the type of the storage key. Possible values are `StorageAccessKey` and `SharedAccessKey`.
- `administrator_login` - (Required) Specifies the login of the administrator.
- `administrator_password` - (Required) Specifies the password of the administrator.
- `authentication_type` - (Required) Specifies the authentication type. Possible values are `SQL` and `Windows`.
- `storage_account_id` - (Required) Specifies the ID of the storage account to import the database from.

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

### <a name="input_lock"></a> [lock](#input\_lock)

Description:   Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_long_term_retention_policy"></a> [long\_term\_retention\_policy](#input\_long\_term\_retention\_policy)

Description: Controls the Long Term Retention Policy configuration on this resource. The following properties can be specified:

- `weekly_retention` - (Required) Specifies the weekly retention policy.
- `monthly_retention` - (Required) Specifies the monthly retention policy.
- `yearly_retention` - (Required) Specifies the yearly retention policy.
- `week_of_year` - (Required) Specifies the week of the year to apply the yearly retention policy.

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

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:   Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

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

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_sample_name"></a> [sample\_name](#input\_sample\_name)

Description: The name of the sample database.

Type: `string`

Default: `null`

### <a name="input_short_term_retention_policy"></a> [short\_term\_retention\_policy](#input\_short\_term\_retention\_policy)

Description: Controls the Short Term Retention Policy configuration on this resource. The following properties can be specified:

- `retention_days` - (Required) Specifies the number of days to keep in the Short Term Retention audit logs.
- `backup_interval_in_hours` - (Required) Specifies the interval in hours to keep in the Short Term Retention audit logs.

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
  "backup_interval_in_hours": 12,
  "retention_days": 35
}
```

### <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name)

Description: The SKU name for the database.

Type: `string`

Default: `"P2"`

### <a name="input_storage_account_type"></a> [storage\_account\_type](#input\_storage\_account\_type)

Description: The type of storage account for the database.

Type: `string`

Default: `"Geo"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_threat_detection_policy"></a> [threat\_detection\_policy](#input\_threat\_detection\_policy)

Description: Controls the Threat Detection Policy configuration on this resource. The following properties can be specified:

- `state` - (Required) Specifies the state of the policy. Possible values are `Enabled` and `Disabled`.
- `disabled_alerts` - (Required) Specifies the list of alerts that are disabled.
- `email_account_admins` - (Required) Specifies the email address to which the alerts are sent.
- `email_addresses` - (Required) Specifies the list of email addresses to which the alerts are sent.
- `retention_days` - (Required) Specifies the number of days to keep in the Threat Detection audit logs.
- `storage_account_access_key` - (Required) Specifies the access key of the storage account to which the Threat Detection audit logs are sent.
- `storage_endpoint` - (Required) Specifies the endpoint of the storage account to which the Threat Detection audit logs are sent.

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

Default: `null`

### <a name="input_transparent_data_encryption_enabled"></a> [transparent\_data\_encryption\_enabled](#input\_transparent\_data\_encryption\_enabled)

Description: Whether transparent data encryption is enabled for the database.

Type: `bool`

Default: `true`

### <a name="input_transparent_data_encryption_key_automatic_rotation_enabled"></a> [transparent\_data\_encryption\_key\_automatic\_rotation\_enabled](#input\_transparent\_data\_encryption\_key\_automatic\_rotation\_enabled)

Description: The key vault key name for transparent data encryption.

Type: `bool`

Default: `null`

### <a name="input_transparent_data_encryption_key_vault_key_id"></a> [transparent\_data\_encryption\_key\_vault\_key\_id](#input\_transparent\_data\_encryption\_key\_vault\_key\_id)

Description: The key vault key ID for transparent data encryption.

Type: `string`

Default: `null`

### <a name="input_zone_redundant"></a> [zone\_redundant](#input\_zone\_redundant)

Description: Whether the database is zone redundant.

Type: `bool`

Default: `true`

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