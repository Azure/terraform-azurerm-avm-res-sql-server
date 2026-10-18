# terraform-azurerm-avm-sql-server

This is a resource module repo for SQL Server on Azure.

Private endpoint locks and role assignments are applied to the endpoint in both DNS-management modes. Endpoints inherit the server's `lock` when no endpoint lock is supplied; set an endpoint's `lock.kind` to `None` to opt out. Existing endpoint names and resource addresses are unchanged.

The endpoint `subresource_name` and IP configuration `member_name` default to `sqlServer`; supplied values are forwarded rather than ignored. `resource_group_name` remains a resource group **name**, not an ID. A role assignment's `skip_service_principal_aad_check = true` selects `ServicePrincipal` when `principal_type` is omitted. AzAPI does not query the directory.

> [!WARNING]
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>
