variable "elastic_pools" {
  description = "Map of elastic pools configurations."

  type = map(object({
    sku = object({
      name     = string
      capacity = number
      tier     = string
      family   = optional(string)
    })
    per_database_settings = object({
      min_capacity = number
      max_capacity = number
    })
    maintenance_configuration_name = optional(string, "SQL_Default")
    zone_redundant                 = optional(bool, "true")
    license_type                   = optional(string)
    max_size_gb                    = optional(number)
  }))

  validation {
    condition = can(
      [for pool, config in var.elastic_pools :

        (config.sku.name == "BasicPool" || config.sku.name == "StandardPool" || config.sku.name == "PremiumPool") &&
        config.sku.tier == "Basic" || config.sku.tier == "Standard" || config.sku.tier == "Premium" &&
        config.sku.family == null
        ||
        (config.sku.name == "GP_Gen4" || config.sku.name == "GP_Gen5" || config.sku.name == "GP_Fsv2" || config.sku.name == "GP_DC" ||
        config.sku.name == "BC_Gen4" || config.sku.name == "BC_Gen5" || config.sku.name == "BC_DC" || config.sku.name == "HS_Gen5") &&
        config.sku.tier == "GeneralPurpose" || config.sku.tier == "BusinessCritical" &&
        config.sku.family != null
      ]
    )
    error_message = "Invalid combination of 'sku' configurations in the elastic_pools variable."
  }

  validation {
    condition = can(
      [for pool, config in var.elastic_pools :
        config.per_database_settings.min_capacity != null && config.per_database_settings.max_capacity != null
      ]
    )
    error_message = "Both 'min_capacity' and 'max_capacity' must be specified for the per_database_settings block in the elastic_pools variable."
  }

  validation {
    condition = can(
      [for pool, config in var.elastic_pools :
        contains([
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
        ], config.maintenance_configuration_name)
      ]
    )
    error_message = "Invalid value for 'maintenance_configuration_name' in the elastic_pools variable."
  }

  validation {
    condition = can(
      [for pool, config in var.elastic_pools :
        config.zone_redundant == null || !config.zone_redundant || (config.sku.tier == "Premium" || config.sku.tier == "BusinessCritical") && config.zone_redundant
      ]
    )
    error_message = "Invalid combination of 'zone_redundant' setting in the elastic_pools variable."
  }

  validation {
    condition = can(
      [for pool, config in var.elastic_pools :
        (config.license_type == null) || contains(["LicenseIncluded", "BasePrice"], config.license_type)
      ]
    )
    error_message = "Invalid value for 'license_type' in the elastic_pools variable."
  }

  validation {
    condition = can(
      [for pool, config in var.elastic_pools :
        (config.max_size_gb == null) || (config.max_size_gb >= 50)
      ]
    )
    error_message = "Invalid value for 'max_size_gb' in the elastic_pools variable. Must be null or a non-negative number."
  }

  default = {}
}
