---
title: "ArgoCD CLI Usage"
weight: 40
---

## What is ArgoCD CLI?

The ArgoCD Command Line Interface (CLI) is a powerful tool that allows you to interact with ArgoCD from the command line. It provides the same functionality as the web dashboard but in a scriptable, automation-friendly format.

### Key Features
- **Application Management**: Create, update, delete, and sync applications
- **Repository Management**: Add and manage Git repositories
- **Cluster Management**: Register and manage Kubernetes clusters
- **Resource Inspection**: View application resources and their status
- **Automation Support**: Perfect for CI/CD pipelines and scripts

## Installing ArgoCD CLI

### Download and Install

```bash
# Download the latest ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

# Make it executable
chmod +x argocd-linux-amd64

# Move to PATH
sudo mv argocd-linux-amd64 /usr/local/bin/argocd

# Verify installation
argocd version --client
```

### Alternative Installation Methods

**Using Package Managers:**
```bash
# macOS with Homebrew
brew install argocd

# Linux with snap
sudo snap install argocd
```

## Authenticating with Tokens

### Login with Token

```bash
# Login using your generated token
argocd login <argocd-server-url> --auth-token <your-token>

# Example
argocd login argocd-server-argocd-hub.us-west-2.amazonaws.com --auth-token argocd-server:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Environment Variable Method

```bash
# Set token as environment variable
export ARGOCD_AUTH_TOKEN="argocd-server:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
export ARGOCD_SERVER="argocd-server-argocd-hub.us-west-2.amazonaws.com"

# Login using environment variables
argocd login $ARGOCD_SERVER --auth-token $ARGOCD_AUTH_TOKEN
```

## Common CLI Commands

### Application Management

```bash
# List all applications
argocd app list

# Get application details
argocd app get <app-name>

# Sync an application
argocd app sync <app-name>

# Get application status
argocd app status <app-name>

# View application resources
argocd app resources <app-name>
```

### Repository Management

```bash
# List repositories
argocd repo list

# Add a repository
argocd repo add <repo-url> --username <user> --password <token>

# Remove a repository
argocd repo rm <repo-url>
```

### Cluster Management

```bash
# List clusters
argocd cluster list

# Add a cluster
argocd cluster add <context-name>

# Remove a cluster
argocd cluster rm <cluster-url>
```

## Practical Examples

### Sync All Applications

```bash
#!/bin/bash
# Script to sync all applications

# Get list of applications
apps=$(argocd app list -o name)

# Sync each application
for app in $apps; do
    echo "Syncing $app..."
    argocd app sync $app --timeout 300
done
```

### Check Application Health

```bash
#!/bin/bash
# Check health of all applications

argocd app list -o wide | grep -E "(OutOfSync|Degraded|Unknown)"
```

### Automated Deployment

```bash
#!/bin/bash
# Deploy application and wait for sync

APP_NAME="retail-store-ui"
TIMEOUT=600

# Sync application
argocd app sync $APP_NAME

# Wait for sync to complete
argocd app wait $APP_NAME --timeout $TIMEOUT

# Check final status
argocd app status $APP_NAME
```

## CLI Configuration

### Configuration File

ArgoCD CLI stores configuration in `~/.argocd/config`:

```yaml
contexts:
  argocd-server-argocd-hub.us-west-2.amazonaws.com:
    server: argocd-server-argocd-hub.us-west-2.amazonaws.com
    auth-token: argocd-server:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
current-context: argocd-server-argocd-hub.us-west-2.amazonaws.com
```

### Multiple Contexts

```bash
# Switch between different ArgoCD instances
argocd context list
argocd context use <context-name>
```

## Use Cases for ArgoCD CLI

### Local Development
- **Quick Sync**: Sync applications after code changes
- **Status Check**: Monitor deployment progress
- **Troubleshooting**: Inspect resources and logs

### CI/CD Pipelines
- **Automated Deployment**: Trigger syncs after successful builds
- **Health Checks**: Verify deployment success
- **Rollback**: Revert to previous versions on failure

### Operations and Monitoring
- **Bulk Operations**: Sync multiple applications
- **Status Monitoring**: Check health across environments
- **Maintenance**: Repository and cluster management

## Security Considerations

### Token Management
- **Environment Variables**: Store tokens in secure environment variables
- **CI/CD Secrets**: Use pipeline secret management for tokens
- **Local Storage**: Secure local configuration files appropriately

### Access Control
- **Least Privilege**: Use tokens with minimal required permissions
- **Audit Logging**: Monitor CLI usage and access patterns
- **Regular Rotation**: Rotate tokens according to security policies

{{% notice tip %}}
**Best Practice**: For production automation, consider using service accounts with project-scoped permissions rather than user-generated tokens.
{{% /notice %}}

## Troubleshooting CLI Issues

### Common Problems
- **Authentication Errors**: Check token validity and expiration
- **Connection Issues**: Verify server URL and network connectivity
- **Permission Denied**: Ensure user has required permissions
- **Command Not Found**: Verify CLI installation and PATH

### Debug Mode
```bash
# Enable debug logging
argocd app sync <app-name> --loglevel debug

# Verbose output
argocd app list -v
```

This completes the ArgoCD access chapter. You now have the knowledge to authenticate users, access the dashboard, and use the CLI for both interactive and automated ArgoCD operations.
