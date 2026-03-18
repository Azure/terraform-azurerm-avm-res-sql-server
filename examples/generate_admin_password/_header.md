# Generate administrator password example

This example demonstrates the `generate_administrator_login_password` and `administrator_login_password_key_vault_configuration` features.

- No password is supplied to the module — it auto-generates a 128-character cryptographically random password.
- The generated password is stored automatically as a secret in an Azure Key Vault.
- The secret can be retrieved after deployment using the `admin_password_key_vault_secret_id` output or via the Azure CLI:

```bash
az keyvault secret show --id <admin_password_key_vault_secret_id>
```
