# SQL Server with TDE Auto-Rotation Example

This example demonstrates how to configure an Azure SQL Server with Transparent Data Encryption (TDE) using customer-managed keys (CMK) from Azure Key Vault with automatic key rotation enabled.

## Features Demonstrated

- **Customer-Managed TDE Keys**: SQL Server configured with TDE using keys stored in Azure Key Vault
- **Automatic Key Rotation**: Server automatically detects and rotates to new key versions within 24 hours
- **User-Assigned Managed Identity**: SQL Server uses managed identity to access Key Vault
- **Key Vault Configuration**: Properly configured Key Vault with access policies for SQL Server
- **Key Rotation Policy**: Optional automatic key rotation policy configured in Key Vault

## Security Benefits

1. **Zero-Touch Key Rotation**: Automatically updates to new key versions without manual intervention
2. **Enhanced Compliance**: Meets security requirements for periodic key rotation
3. **Reduced Operational Overhead**: No manual key rotation required
4. **Data Protection**: Customer-managed keys provide additional control over encryption keys

## How It Works

When `transparent_data_encryption_key_automatic_rotation_enabled` is set to `true`:

1. The SQL Server continuously monitors the configured Key Vault key
2. When a new version of the key is detected (either manually created or via Key Vault auto-rotation)
3. The TDE protector on the server is automatically rotated to the latest key version within 24 hours
4. Only the database encryption key is re-encrypted, not the entire database
5. The process is online with minimal impact

## Important Considerations

- **Purge Protection**: Key Vault must have purge protection enabled for TDE
- **Required Permissions**: SQL Server identity needs `Get`, `WrapKey`, and `UnwrapKey` permissions
- **Geo-Replication**: Additional configuration required for geo-replicated servers
- **Key Versions**: Only the latest key version is used; previous versions are maintained for backup/restore
