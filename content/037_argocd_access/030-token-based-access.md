---
title: "Token-Based Access"
weight: 30
---

## ArgoCD Authentication Tokens

ArgoCD supports token-based authentication for programmatic access and CLI usage. These tokens provide an alternative to interactive SSO login.

### Token Characteristics

- **Duration**: Tokens are valid for 12 hours by default
- **Scope**: Inherit the same permissions as the user who generated them
- **Usage**: Primarily for CLI access and automation
- **Security**: Should be treated as sensitive credentials

## Generating Tokens

### Through ArgoCD Dashboard

1. **Access User Settings**
   - Log into ArgoCD dashboard
   - Click on your user profile (top right)
   - Select "User Info" or "Settings"

2. **Generate New Token**
   - Navigate to "Tokens" section
   - Click "Generate New Token"
   - Provide a descriptive name for the token
   - Set expiration time (default 12 hours)

3. **Copy Token**
   - Copy the generated token immediately
   - Store securely - it won't be shown again
   - The token format: `argocd-server:<base64-encoded-token>`

### Token Security

{{% notice warning %}}
**Security Best Practices**:
- Never share tokens in plain text
- Store tokens securely (password managers, secure vaults)
- Rotate tokens regularly
- Revoke unused or compromised tokens immediately
{{% /notice %}}

## Token Limitations

### Expiration
- **Default Expiry**: 12 hours from generation
- **No Refresh**: Tokens cannot be refreshed, must generate new ones
- **Automatic Cleanup**: Expired tokens are automatically removed

### Permissions
- **User-Based**: Tokens inherit the exact permissions of the generating user
- **No Escalation**: Cannot grant more permissions than the user has
- **Role-Based**: Admin users generate admin tokens, viewers generate viewer tokens

## When to Use Tokens

### Recommended Use Cases
- **Local Development**: ArgoCD CLI usage on developer machines
- **Automation Scripts**: Programmatic access to ArgoCD APIs
- **CI/CD Pipelines**: Automated deployment and synchronization
- **Monitoring Tools**: Health checks and status monitoring

### Not Recommended
- **Long-term Storage**: Due to 12-hour expiration
- **Shared Access**: Each user should generate their own tokens
- **Production Services**: Consider service accounts for production automation

## Best Practices

### Token Management
1. **Descriptive Names**: Use clear, descriptive names for tokens
2. **Regular Rotation**: Generate new tokens regularly
3. **Immediate Revocation**: Revoke tokens when no longer needed
4. **Secure Storage**: Use secure credential storage systems

### Access Patterns
1. **Principle of Least Privilege**: Generate tokens with minimal required permissions
2. **Time-Limited**: Use shortest practical expiration time
3. **Audit Trail**: Monitor token usage and access patterns
4. **Emergency Procedures**: Have procedures for token compromise scenarios

## Alternative: Project-Based Tokens

For production environments, consider:
- **Service Accounts**: Dedicated accounts for automation
- **Project-Scoped Tokens**: Tokens limited to specific projects/applications
- **Role-Based Tokens**: Custom roles with minimal required permissions

{{% notice info %}}
**Production Recommendation**: Use project-based access control and service accounts rather than user-generated tokens for production automation and CI/CD pipelines.
{{% /notice %}}

## Next Steps

In the next section, we'll explore how to use these tokens with the ArgoCD CLI for command-line access and automation.
