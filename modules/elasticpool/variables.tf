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
  default     = null
  description = "The maximum size of the elastic pool in GB."
}

variable "per_database_settings" {
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = {
    max_capacity = 10
    min_capacity = 0
  }
  description = "The per-database settings for the elastic pool."
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
    capacity = 50
    tier     = "Premium"
    family   = "Gen5"
  }
  description = "The SKU details for the elastic pool."
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
