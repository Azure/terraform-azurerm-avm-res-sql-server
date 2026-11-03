# terraform-azurerm-avm-sql-server

This is a resource module repo for SQL Server on Azure.

Private endpoint locks and role assignments are applied to the endpoint in both DNS-management modes. Endpoints inherit the server's `lock` when no endpoint lock is supplied; set an endpoint's `lock.kind` to `None` to opt out. Existing endpoint names and resource addresses are unchanged.

The endpoint `subresource_name` and IP configuration `member_name` default to `sqlServer`; supplied values are forwarded rather than ignored. `resource_group_name` remains a resource group **name**, not an ID. A role assignment's `skip_service_principal_aad_check = true` selects `ServicePrincipal` when `principal_type` is omitted. AzAPI does not query the directory.

## Upgrading to the AzAPI resources

Resources move from AzureRM to AzAPI with `moved` blocks, so the plan after upgrading reports them as moved and Azure keeps them. These cases need extra steps:

- **`ReadOnly` lock.** The upgrade updates resources in place, which a `ReadOnly` lock blocks. Before upgrading, apply your configuration without the lock using the old version, then upgrade and restore the lock.
- **Cross-tenant role assignments** (those that set `delegated_managed_identity_resource_id`, for example with Azure Lighthouse). The AzureRM provider stored their ID with a `|<tenant-id>` suffix that a `moved` block cannot convert. Before planning, remove each one from the state, then import it at its new address with an `import` block in your root module. For a database or elastic pool, use `module.<module-name>.module.database["<database key>"]` or `module.<module-name>.module.elasticpool["<pool key>"]` instead of `module.<module-name>`:

  ```shell
  terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
  ```

  ```hcl
  import {
    to = module.<module-name>.azapi_resource.role_assignments["<key>"]
    id = "<role assignment resource ID, without the |<tenant-id> suffix>"
  }
  ```

- **Private DNS zone groups managed by the module** (`private_endpoints_manage_dns_zone_group` is true, the default, and a private endpoint sets `private_dns_zone_resource_ids`). The AzureRM provider kept the zone group inside the private endpoint, so there is no separate address for a `moved` block to start from, and AzAPI does not take over an existing resource it did not create. Import each zone group once with an `import` block in your root module:

  ```hcl
  import {
    to = module.<module-name>.azapi_resource.private_dns_zone_groups["<key>"]
    id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Network/privateEndpoints/<private-endpoint-name>/privateDnsZoneGroups/<zone-group-name>?api-version=2024-05-01"
  }
  ```

  `<key>` is the key of the `private_endpoints` entry, `<private-endpoint-name>` is its `name` (`pep-<server name>` by default), and `<zone-group-name>` is its `private_dns_zone_group_name` (`default` by default). The import leaves the zone group and its DNS records unchanged. Without it, the apply stops with `Resource already exists`, and nothing in Azure is removed; add the block and apply again. Remove the block once the upgrade is applied.

> [!WARNING]
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>
