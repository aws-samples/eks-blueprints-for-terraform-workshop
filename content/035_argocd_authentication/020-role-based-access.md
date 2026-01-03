---
title: "Role-Based Access Control"
weight: 40
---

### 1. ArgoCD Built-in Roles

Amazon EKS managed ArgoCD provides three built-in roles that offer broad access to all applications:

- ADMIN: Full access to all applications and settings:
- EDITOR: Can create and modify applications but cannot change Argo CD settings:
- VIEWER: Read-only access to applications

The built-in roles provide broad access across all applications. 

For example:
- An Admin user can manage all applications (retail-store, payment, ecommerce etc)
- An Editor can modify any application in the system
- A Viewer can see all applications and their configurations



### 2. Granular Access Control

For more granular permissions, ArgoCD supports Project-based Access Control where you can:

- Scope users to specific applications(retail-store, payment, ecommerce etc)
- Limit actions within applications (sync only, create only, etc.)

We will cover this in upcoming chapter

### 3. argoadmin user

We have assigned ArgocdAdmins group to built in "Admins" group. This makes argoadmin superuser.

To view Navigate to EKS>Clusters>argocd-hub>Capabilites>Argo CD on AWS Console

![argoadmin role ](/static/images/argocd-authentication/argocdadmins-role.png)


You can get find best pratices from the [documentation](https://docs.aws.amazon.com/eks/latest/userguide/argocd-permissions.html#_best_practices)

