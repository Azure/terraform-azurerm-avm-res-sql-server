# SQL Server with TDE Key Auto-Rotation Example

This example demonstrates how to configure Transparent Data Encryption (TDE) with Customer Managed Keys (CMK) and automatic key rotation for an Azure SQL Server and database. It creates:

- A user-assigned managed identity for the SQL Server
- An Azure Key Vault with a key and rotation policy
- An Azure SQL Server using CMK-based TDE via the Key Vault key
- A database with `transparent_data_encryption_key_automatic_rotation_enabled` set to `true`
