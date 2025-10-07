## Benefits of Ephemeral Secrets

1. **Enhanced Security**: Passwords are never stored in Terraform state files
2. **Compliance**: Meets enterprise security requirements for credential management
3. **Rotation Support**: Version tracking enables automated password rotation
4. **Backward Compatibility**: Existing `administrator_login_password` usage remains unchanged

## Usage Pattern

This example shows how to use the new ephemeral secrets feature where:
- `administrator_login_password_wo` provides the password in write-only mode
- `administrator_login_password_wo_version` tracks the password version for rotation purposes
- The password is never stored in the Terraform state file
