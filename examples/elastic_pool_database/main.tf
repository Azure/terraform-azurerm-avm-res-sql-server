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
  location = "eastus" # eastus supports Gen5, Fsv2, DC-series, and all Hyperscale hardware
  name     = module.naming.resource_group.name_unique
}

resource "random_password" "admin_password" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

locals {
  # One database per elastic pool — each exercises a different SKU combination
  # for validation coverage of the modified elastic pool SKU variable.
  databases = {
    for k, v in local.elastic_pools : "db_${k}" => {
      name             = "db-${replace(v.name, "_", "-")}"
      create_mode      = "Default"
      collation        = "SQL_Latin1_General_CP1_CI_AS"
      elastic_pool_key = k
      license_type     = "LicenseIncluded"
      sku_name         = "ElasticPool"

      # Hyperscale does not support short_term_retention_policy; omit the block entirely.
      short_term_retention_policy = v.sku.tier == "Hyperscale" ? null : {
        retention_days           = 1
        backup_interval_in_hours = 24
      }
    }
  }
  elastic_pools = {
    # ── DTU-based ────────────────────────────────────────────────────────────
    basic_pool = {
      name = "basic_pool"
      sku = {
        name     = "BasicPool"
        capacity = 50
        tier     = "Basic"
        family   = null
      }
      per_database_settings = { min_capacity = 0, max_capacity = 5 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
      max_size_gb           = 4.8828125 # BasicPool: 50 DTUs × 0.09765625 GB/DTU
    }
    standard_pool = {
      name = "standard_pool"
      sku = {
        name     = "StandardPool"
        capacity = 50
        tier     = "Standard"
        family   = null
      }
      per_database_settings = { min_capacity = 0, max_capacity = 50 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
      max_size_gb           = 50
    }
    premium_pool = {
      name = "premium_pool"
      sku = {
        name     = "PremiumPool"
        capacity = 125
        tier     = "Premium"
        family   = null
      }
      per_database_settings = { min_capacity = 0, max_capacity = 125 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
      max_size_gb           = 50
    }

    # ── vCore — General Purpose ───────────────────────────────────────────────
    # Note: GP_Gen4 is omitted — Gen4 hardware is fully retired and cannot be provisioned.
    gp_gen5_pool = {
      name = "gp_gen5_pool"
      sku = {
        name     = "GP_Gen5"
        capacity = 2
        tier     = "GeneralPurpose"
        family   = "Gen5"
      }
      per_database_settings = { min_capacity = 0, max_capacity = 2 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
      max_size_gb           = 50
    }
    gp_fsv2_pool = {
      name = "gp_fsv2_pool"
      sku = {
        name     = "GP_Fsv2"
        capacity = 8 # Fsv2 minimum valid capacity; valid: 8,10,12,14,16,18,20,24,32,36,72
        tier     = "GeneralPurpose"
        family   = "Fsv2"
      }
      per_database_settings = { min_capacity = 0, max_capacity = 8 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
      max_size_gb           = 50
    }
    gp_dc_pool = {
      name = "gp_dc_pool"
      sku = {
        name     = "GP_DC"
        capacity = 2
        tier     = "GeneralPurpose"
        family   = "DC"
      }
      per_database_settings = { min_capacity = 0, max_capacity = 2 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
      max_size_gb           = 50
    }

    # ── vCore — Business Critical ─────────────────────────────────────────────
    # Note: BC_Gen4 is omitted — Gen4 hardware is fully retired and cannot be provisioned.
    bc_gen5_pool = {
      name = "bc_gen5_pool"
      sku = {
        name     = "BC_Gen5"
        capacity = 4
        tier     = "BusinessCritical"
        family   = "Gen5"
      }
      per_database_settings = { min_capacity = 0, max_capacity = 4 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
      max_size_gb           = 50
    }
    bc_dc_pool = {
      name = "bc_dc_pool"
      sku = {
        name     = "BC_DC"
        capacity = 2
        tier     = "BusinessCritical"
        family   = "DC"
      }
      per_database_settings = { min_capacity = 0, max_capacity = 2 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
      max_size_gb           = 50
    }

    # ── vCore — Hyperscale ────────────────────────────────────────────────────
    hs_gen5_pool = {
      name = "hs_gen5_pool"
      sku = {
        name     = "HS_Gen5"
        capacity = 4
        tier     = "Hyperscale"
        family   = "Gen5"
      }
      per_database_settings = { min_capacity = 0, max_capacity = 4 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
    }
    hs_prms_pool = {
      name = "hs_prms_pool"
      sku = {
        name     = "HS_PRMS"
        capacity = 4
        tier     = "Hyperscale"
        family   = "PRMS"
      }
      per_database_settings = { min_capacity = 0, max_capacity = 4 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
    }
    hs_moprms_pool = {
      name = "hs_moprms_pool"
      sku = {
        name     = "HS_MOPRMS"
        capacity = 4
        tier     = "Hyperscale"
        family   = "MOPRMS"
      }
      per_database_settings = { min_capacity = 0, max_capacity = 4 }
      zone_redundant        = false
      license_type          = "LicenseIncluded"
    }
  }
}

# This is the module call
module "sql_server" {
  source = "../../"

  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  server_version               = "12.0"
  administrator_login          = "mysqladmin"
  administrator_login_password = random_password.admin_password.result
  databases                    = local.databases
  elastic_pools                = local.elastic_pools
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  enable_telemetry = var.enable_telemetry
  name             = module.naming.sql_server.name_unique
}
