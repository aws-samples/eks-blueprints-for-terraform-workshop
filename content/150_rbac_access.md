---
title: "RBAC Access"
weight: 150
---

<!-- cspell:disable-next-line -->

::video{id=\_rLiHT2BgiQ}

In this chapter, you'll experience role-based access control by logging in as a user with limited permissions. The "retaildev" user has access only to the dev environment through the retail-store-dev project.

ArgoCD Projects implement RBAC through:

- Roles: Define permission sets (team-lead, developer, devops)
- Policies: Specify what each role can do
- Groups: Users inherit permissions through group membership

The retail-store-dev project has three roles with different access levels:

- Team Lead: Full access to applications, get repositories, and clusters
- Developer: Can create and sync applications, but cannot delete
- DevOps: Can sync and manage deployments

The "retaildev" user belongs to the Developer group, giving them limited access.

### 1. Generate password

You can follow steps in in chapter "ArgoCD Authentication Setup">"User Management" to generate temporary password for "retaildev" user

### 2. Logout from ArgoCD dashboard

So far you have setup automation in this workshop as "argoadmin" which has admin privileges in ArgoCD. You can logoff by clicking "Log out" button.

### 3. Login as "retaildev"

When you login as "retaildev", you'll immediately notice the difference in access:

What You Can See:

- ✅ Applications in the retail-store-dev project (cart, catalog, checkout, orders, ui)
- ✅ Only dev environment applications

What You Cannot See:

- ❌ Production applications (retail-store-prod project)
- ❌ Platform automation applications (admin-hub project)
- ❌ Other teams' applications

This demonstrates project-level isolation - users only see resources within their assigned projects.

![Dashboard](/static/images/rbac/dashboard.png)

### 4. Understanding Token Scopes

In the chapter "Accessing ArgoCD" > "Token Based Access", you learned about Account Tokens. Now you'll learn about Project Tokens, which provide better security through limited scope.

Account Tokens:

- Scope: Global access to all projects/apps the user has permissions for
- Duration: Fixed 12 hours
- Use Case: Admin users who need access across multiple projects
- Created from: User Settings → Tokens

Project Tokens:

- Scope: Limited to a single project only
- Duration: Configurable up to 1 year
- Use Case: Team members who work within one project
- Created from: Project Settings → Role Tokens

Recommendation: Use project-based tokens for better security. They follow the principle of least privilege by limiting access to only what's needed.

### 5. Generate Project Token via UI

1. Navigate to "Settings→Projects"
2. You'll see only "retail-store-dev" (the only project you have access to)
3. Click on retail-store-dev
4. Go to the Roles tab
5. Select the developer role
6. Click Create Token
7. (Optional) Set an expiration time
8. Copy the generated token and store it securely

![Generate Token](/static/images/rbac/generate-token.png)

### 6. Using Project Tokens via CLI

After generating your project token, you need to configure your environment to use it.

Set your environment variables.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml }
export ARGOCD_AUTH_TOKEN=<<your token>>
export ARGOCD_SERVER=<<ArgoCD dashboard url without https://>>
export ARGOCD_OPTS="--grpc-web"
:::
<!-- prettier-ignore-end -->

Verify your access:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=bash }
# list applications. Notice you only see retail-store-dev applications - production and platform apps are hidden.
argocd app list
NAME                                              CLUSTER  NAMESPACE  PROJECT           STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                                                                         PATH          TARGET
argocd/team-retail-store-deployment-cart-dev      dev      cart       retail-store-dev  Synced  Healthy  Auto-Prune  <none>      https://git-codecommit.us-west-2.amazonaws.com/v1/repos/retail-store-config  cart/dev      HEAD
argocd/team-retail-store-deployment-catalog-dev   dev      catalog    retail-store-dev  Synced  Healthy  Auto-Prune  <none>      https://git-codecommit.us-west-2.amazonaws.com/v1/repos/retail-store-config  catalog/dev   HEAD
argocd/team-retail-store-deployment-checkout-dev  dev      checkout   retail-store-dev  Synced  Healthy  Auto-Prune  <none>      https://git-codecommit.us-west-2.amazonaws.com/v1/repos/retail-store-config  checkout/dev  HEAD
argocd/team-retail-store-deployment-orders-dev    dev      orders     retail-store-dev  Synced  Healthy  Auto-Prune  <none>      https://git-codecommit.us-west-2.amazonaws.com/v1/repos/retail-store-config  orders/dev    HEAD
argocd/team-retail-store-deployment-ui-dev        dev      ui         retail-store-dev  Synced  Healthy  Auto-Prune  <none>      https://git-codecommit.us-west-2.amazonaws.com/v1/repos/retail-store-config  ui/dev        HEAD

# Try to delete an application (should fail - developer role cannot delete)
argocd app delete team-retail-store-deployment-cart-dev
Are you sure you want to delete 'team-retail-store-deployment-cart-dev' and all its resources? [y/n] y
FATA[0003] rpc error: code = PermissionDenied desc = permission denied: applications, delete, retail-store-dev/team-retail-store-deployment-cart-dev, sub: proj:retail-store-dev:developer, iat: 2026-01-24T23:18:06Z 
:::
<!-- prettier-ignore-end -->
