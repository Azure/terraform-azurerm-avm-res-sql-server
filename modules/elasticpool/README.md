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
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Sql/servers/mySqlServer"
  }
  name     = "my-elasticpool"
  location = "eastus"
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
- [azurerm_mssql_elasticpool.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_elasticpool) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)

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

### <a name="input_license_type"></a> [license\_type](#input\_license\_type)

Description: The license type for the elastic pool.

Type: `string`

Default: `"LicenseIncluded"`

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

Default: `50`

### <a name="input_per_database_settings"></a> [per\_database\_settings](#input\_per\_database\_settings)

Description: The per database settings for the elastic pool.

- `min_capacity` - The minimum capacity of the elastic pool in DTUs or vCores.
- `max_capacity` - The maximum capacity of the elastic pool in DTUs or vCores.

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
  "max_capacity": 25,
  "min_capacity": 0
}
```

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

### <a name="input_sku"></a> [sku](#input\_sku)

Description: The SKU of the elastic pool.

- `name` - The name of the SKU.
- `capacity` - The capacity of the SKU.
- `tier` - The tier of the SKU.
- `family` - The family of the SKU.

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
  "capacity": 125,
  "family": null,
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