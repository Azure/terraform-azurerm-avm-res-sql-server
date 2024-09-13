variable "location" {
  type        = string
  description = "The location of the elastic pool."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the elastic pool."
  nullable    = false
}

variable "sql_server" {
  type = object({
    resource_id = string
  })
  description = "The resource ID of the SQL Server to create the elastic pool on."
  nullable    = false
}

variable "diagnostic_settings" {
  type = map(object({
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
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
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
  DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "license_type" {
  type        = string
  default     = "LicenseIncluded"
  description = "The license type for the elastic pool."
  nullable    = false

  validation {
    condition     = contains(["LicenseIncluded", "BasePrice"], var.license_type)
    error_message = "Invalid value for license_type."
  }
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:
  
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "maintenance_configuration_name" {
  type        = string
  default     = "SQL_Default"
  description = "The name of the maintenance configuration."

  validation {
    condition = contains([
      "SQL_Default",
      "SQL_AustraliaEast_DB_1", "SQL_AustraliaEast_DB_2",
      "SQL_AustraliaSoutheast_DB_1", "SQL_AustraliaSoutheast_DB_2",
      "SQL_BrazilSouth_DB_1", "SQL_BrazilSouth_DB_2", "SQL_BrazilSoutheast_DB_1", "SQL_BrazilSoutheast_DB_2",
      "SQL_CanadaCentral_DB_1", "SQL_CanadaCentral_DB_2", "SQL_CanadaEast_DB_1", "SQL_CanadaEast_DB_2",
      "SQL_CentralIndia_DB_1", "SQL_CentralIndia_DB_2", "SQL_CentralUS_DB_1", "SQL_CentralUS_DB_2",
      "SQL_EastAsia_DB_1", "SQL_EastAsia_DB_2", "SQL_EastUS_DB_1", "SQL_EastUS_DB_2", "SQL_EastUS2_DB_1", "SQL_EastUS2_DB_2",
      "SQL_FranceCentral_DB_1", "SQL_FranceCentral_DB_2", "SQL_FranceSouth_DB_1", "SQL_FranceSouth_DB_2",
      "SQL_GermanyWestCentral_DB_1", "SQL_GermanyWestCentral_DB_2",
      "SQL_JapanEast_DB_1", "SQL_JapanEast_DB_2", "SQL_JapanWest_DB_1", "SQL_JapanWest_DB_2",
      "SQL_NorthCentralUS_DB_1", "SQL_NorthCentralUS_DB_2", "SQL_NorthEurope_DB_1", "SQL_NorthEurope_DB_2",
      "SQL_SouthCentralUS_DB_1", "SQL_SouthCentralUS_DB_2", "SQL_SouthIndia_DB_1", "SQL_SouthIndia_DB_2",
      "SQL_SoutheastAsia_DB_1", "SQL_SoutheastAsia_DB_2", "SQL_SwitzerlandNorth_DB_1", "SQL_SwitzerlandNorth_DB_2",
      "SQL_UAENorth_DB_1", "SQL_UAENorth_DB_2", "SQL_UKSouth_DB_1", "SQL_UKSouth_DB_2", "SQL_UKWest_DB_1", "SQL_UKWest_DB_2",
      "SQL_WestCentralUS_DB_1", "SQL_WestCentralUS_DB_2", "SQL_WestEurope_DB_1", "SQL_WestEurope_DB_2",
      "SQL_WestUS_DB_1", "SQL_WestUS_DB_2", "SQL_WestUS2_DB_1", "SQL_WestUS2_DB_2"
    ], var.maintenance_configuration_name)
    error_message = "value for maintenance_configuration_name is invalid."
  }
}

variable "max_size_bytes" {
  type        = number
  default     = null
  description = "The maximum size of the elastic pool in bytes."
}

variable "max_size_gb" {
  type        = number
  default     = 50
  description = "The maximum size of the elastic pool in GB."
}

variable "per_database_settings" {
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = {
    max_capacity = 25
    min_capacity = 0
  }
  description = <<DESCRIPTION
The per database settings for the elastic pool.

- `min_capacity` - The minimum capacity of the elastic pool in DTUs or vCores.
- `max_capacity` - The maximum capacity of the elastic pool in DTUs or vCores.

DESCRIPTION
  nullable    = false

  validation {
    condition     = var.per_database_settings.min_capacity >= 0 && var.per_database_settings.max_capacity >= 0
    error_message = "min_capacity and max_capacity must be greater than or equal to 0."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  nullable    = false
}

variable "sku" {
  type = object({
    name     = string
    capacity = number
    tier     = string
    family   = optional(string)
  })
  default = {
    name     = "PremiumPool"
    capacity = 125
    tier     = "Premium"
    family   = null
  }
  description = <<DESCRIPTION
The SKU of the elastic pool.

- `name` - The name of the SKU.
- `capacity` - The capacity of the SKU.
- `tier` - The tier of the SKU.
- `family` - The family of the SKU.
DESCRIPTION  
  nullable    = false

  validation {
    condition     = ((var.sku.name == "BasicPool" || var.sku.name == "StandardPool" || var.sku.name == "PremiumPool") && (var.sku.tier == "Basic" || var.sku.tier == "Standard" || var.sku.tier == "Premium") && var.sku.family == null) || ((var.sku.name == "GP_Gen4" || var.sku.name == "GP_Gen5" || var.sku.name == "GP_Fsv2" || var.sku.name == "GP_DC" || var.sku.name == "BC_Gen4" || var.sku.name == "BC_Gen5" || var.sku.name == "BC_DC" || var.sku.name == "HS_Gen5") && (var.sku.tier == "GeneralPurpose" || var.sku.tier == "BusinessCritical") && var.sku.family != null)
    error_message = "Invalid combination of 'sku' configurations in the elastic_pools variable."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "zone_redundant" {
  type        = bool
  default     = true
  description = "Specifies if the elastic pool is zone redundant."

  validation {
    condition     = !var.zone_redundant || ((var.sku.tier == "Premium" || var.sku.tier == "BusinessCritical") && var.zone_redundant)
    error_message = "Combination of SKU and zone_redundant is invalid."
  }
}
