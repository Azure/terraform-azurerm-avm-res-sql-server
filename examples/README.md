# Examples

This module is for the Azure SQL database.  Managed instances & SQL VMs will be created as separate modules.  The following examples illustrate the use of this module:

|Example |Description|
|--|--|
| [default](./default/) | Create a mssql server using the default parameters in this module.
| [database](./database/) | Create a mssql server and a single database.
| [database_with_existing_server](./database_with_existing_server/) | Bring your existing mssql server and add a database.
| [elastic_pool_database](./elastic_pool_database/) | Create a mssql server, one elastic pool & an associated database.
| [private_endpoint](./private_endpoint/) | SQL Server with private endpoint.

## Contributing new examples

New examples to test functionality or illustrate use are welcome.

- Create a directory for each example.
- Create a `_header.md` file in each directory to describe the example.
- See the `default` example provided as a skeleton - this must remain, but you can add others.
- Run `make fmt && make docs` from the repo root to generate the required documentation.

> **Note:** Examples must be deployable and idempotent. Ensure that no input variables are required to run the example and that random values are used to ensure unique resource names. E.g. use the [naming module](https://registry.terraform.io/modules/Azure/naming/azurerm/latest) to generate a unique name for a resource.
