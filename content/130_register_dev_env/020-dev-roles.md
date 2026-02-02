---
title: "Project-Based Access Control - Dev Environment"
weight: 20
hidden: true
---

## Overview

This section demonstrates ArgoCD's project-based access control (RBAC) for the retail-store application in the development environment. Unlike the built-in roles (Admin/Editor/Viewer) that provide broad access to all applications, project-based roles allow granular permissions scoped to specific applications and environments.

## Dev Environment Roles

The retail-store project in the dev environment has three distinct roles:

### **Team Lead Role**

- **Group**: RetailStoreTeamLeads
- **Permissions**: Full project access in dev environment
- **Capabilities**:
  - Create, modify, delete applications
  - Sync and manage all retail-store applications
  - Access to repositories and cluster information
  - Complete control over dev environment

### **Developer Role**

- **Group**: RetailStoreDevelopers
- **Permissions**: Limited access focused on development workflow
- **Capabilities**:
  - Create new applications for testing features
  - View and sync existing applications
  - Perform application actions (restart, rollback)
  - View repository and cluster information
- **Restrictions**:
  - Cannot delete applications
  - Limited to retail-store project only

### **DevOps Role**

- **Group**: RetailStoreDevOps
- **Permissions**: Deployment and operational management
- **Capabilities**:
  - View all applications and their status
  - Sync applications for deployments
  - Perform application actions and overrides
  - Access to logs and troubleshooting information
- **Focus**: Release management and operational tasks

## Benefits of Project-Based Access

### **Granular Control**

- Users only see applications they need to work with
- Permissions are scoped to specific projects and environments
- Reduces risk of accidental changes to unrelated applications

### **Environment Separation**

- Dev roles are completely separate from production access
- Developers can experiment freely without production risk
- Clear boundaries between different environments

### **Team Collaboration**

- Multiple developers can work on the same project
- Different permission levels support various responsibilities
- Team leads maintain oversight while enabling developer autonomy

## Role Comparison

| Capability          | Team Lead | Developer | DevOps    |
| ------------------- | --------- | --------- | --------- |
| View Applications   | ✅        | ✅        | ✅        |
| Create Applications | ✅        | ✅        | ❌        |
| Sync Applications   | ✅        | ✅        | ✅        |
| Delete Applications | ✅        | ❌        | ❌        |
| Override Settings   | ✅        | ❌        | ✅        |
| Repository Access   | ✅        | View Only | View Only |

## Next Steps

In the next section, we'll explore how these roles are implemented differently in the production environment, with more restrictive permissions and additional support roles for operational safety.
