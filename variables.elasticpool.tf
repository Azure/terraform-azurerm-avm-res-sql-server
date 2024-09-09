variable "elastic_pools" {
  type = map(object({
    name     = string
    location = optional(string)
    sku = optional(object({
      name     = string
      capacity = number
      tier     = string
      family   = optional(string)
    }))
    per_database_settings = optional(object({
      min_capacity = number
      max_capacity = number
    }))
    maintenance_configuration_name = optional(string, "SQL_Default")
    zone_redundant                 = optional(bool, "true")
    license_type                   = optional(string)
    max_size_gb                    = optional(number)
    max_size_bytes                 = optional(number)

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })))

    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))

    diagnostic_settings = optional(map(object({
      name                            = optional(string, null)
      event_hub_authorization_rule_id = optional(string, null)
      event_hub_name                  = optional(string, null)
      log_analytics_destination_type  = optional(string, null)
      log_analytics_workspace_id      = optional(string, null)
      marketplace_partner_resource_id = optional(string, null)
      storage_account_resource_id     = optional(string, null)
      log_categories                  = optional(list(string))
      log_groups                      = optional(list(string))
    })))

    tags = optional(map(string))
  }))

  default     = {}
  description = <<DESCRIPTION
A map of objects containing attributes for each Elastic Pool to be created.

- `name` - (Required) Specifies the name of the Elastic Pool. Changing this forces a new resource to be created.
- `location` - (Optional) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.

- `sku` - (Optional) Specifies the SKU of the Elastic Pool. Changing this forces a new resource to be created.
  - `name` - (Required) Specifies the name of the SKU. Changing this forces a new resource to be created.
  - `capacity` - (Required) Specifies the capacity of the SKU. Changing this forces a new resource to be created.
  - `tier` - (Required) Specifies the tier of the SKU. Changing this forces a new resource to be created.
  - `family` - (Optional) Specifies the family of the SKU. Changing this forces a new resource to be created.

- `per_database_settings` - (Optional) Specifies the per database settings for the Elastic Pool. Changing this forces a new resource to be created.
  - `min_capacity` - (Required) Specifies the minimum capacity of the Elastic Pool. Changing this forces a new resource to be created.
  - `max_capacity` - (Required) Specifies the maximum capacity of the Elastic Pool. Changing this forces a new resource to be created.

- `maintenance_configuration_name` - (Optional) Specifies the name of the maintenance configuration to apply to this Elastic Pool. Changing this forces a new resource to be created.
- `zone_redundant` - (Optional) Specifies whether or not this Elastic Pool is zone redundant. Changing this forces a new resource to be created.
- `license_type` - (Optional) Specifies the license type for the Elastic Pool. Changing this forces a new resource to be created.
- `max_size_gb` - (Optional) Specifies the maximum size of the Elastic Pool in gigabytes. Changing this forces a new resource to be created.
- `max_size_bytes` - (Optional) Specifies the maximum size of the Elastic Pool in bytes. Changing this forces a new resource to be created.

- `role_assignments` - (Optional) Specifies the role assignments for the Elastic Pool. Changing this forces a new resource to be created.
  - `role_definition_id_or_name` - (Required) Specifies the ID or name of the role definition to assign to the principal.
  - `principal_id` - (Required) Specifies the ID of the principal to assign the role to.
  - `description` - (Optional) Specifies the description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Specifies whether or not to skip the service principal AAD check.
  - `condition` - (Optional) Specifies the condition of the role assignment.
  - `condition_version` - (Optional) Specifies the condition version of the role assignment.
  - `delegated_managed_identity_resource_id` - (Optional) Specifies the delegated managed identity resource ID of the role assignment.
  - `principal_type` - (Optional) Specifies the principal type of the role assignment.

- `lock` - (Optional) Specifies the lock for the Elastic Pool. Changing this forces a new resource to be created.

- `diagnostic_settings` - (Optional) Specifies the diagnostic settings for the Elastic Pool. Changing this forces a new resource to be created.
  - `name` - (Optional) Specifies the name of the diagnostic setting.
  - `event_hub_authorization_rule_id` - (Optional) Specifies the ID of the event hub authorization rule.
  - `event_hub_name` - (Optional) Specifies the name of the event hub.
  - `log_analytics_destination_type` - (Optional) Specifies the destination type of the log analytics.
  - `log_analytics_workspace_id` - (Optional) Specifies the ID of the log analytics workspace.
  - `marketplace_partner_resource_id` - (Optional) Specifies the ID of the marketplace partner resource.
  - `storage_account_resource_id` - (Optional) Specifies the ID of the storage account.
  - `log_categories` - (Optional) Specifies the log categories of the diagnostic setting.
  - `log_groups` - (Optional) Specifies the log groups of the diagnostic setting.

- `tags` - (Optional) A mapping of tags to assign to the resource.

DESCRIPTION
}
