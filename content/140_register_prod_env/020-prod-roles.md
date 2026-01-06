---
title: "Project-Based Access Control - Production Environment"
weight: 20
hidden: true
---

## Overview

This section demonstrates ArgoCD's project-based access control (RBAC) for the retail-store application in the production environment. Production roles are more restrictive than development roles, focusing on operational safety, change control, and emergency response capabilities.

## Production Environment Roles

The retail-store project in the production environment has three specialized roles designed for production operations:

### **Team Lead Role**

- **Group**: RetailStoreTeamLeads
- **Permissions**: Full project access in production environment
- **Capabilities**:
  - Complete control over production applications
  - Approve and manage production deployments
  - Access to all repositories and cluster information
  - Authority to make critical production decisions
- **Responsibility**: Overall production application lifecycle management

### **DevOps Role**

- **Group**: RetailStoreDevOps
- **Permissions**: Controlled deployment management (more restricted than dev)
- **Capabilities**:
  - View all production applications and their status
  - Sync applications for planned deployments
  - Perform standard application actions
  - Access to operational logs and metrics
- **Restrictions**:
  - Cannot override application settings (removed for production safety)
  - Cannot create or delete applications
- **Focus**: Controlled release management and deployment execution

### **Production Support Role**

- **Group**: RetailStoreProdSupport
- **Permissions**: Read-only with emergency sync capability
- **Capabilities**:
  - View all applications and their current state
  - Emergency sync capability for incident response
  - Access to logs and troubleshooting information
  - Monitor application health and performance
- **Restrictions**:
  - Cannot create, delete, or modify applications
  - Cannot override application configurations
- **Purpose**: 24/7 production monitoring and emergency response

## Production vs Development Differences

### **Removed Roles**

- **No Developer Role**: Developers don't have direct production access
- **Separation of Concerns**: Development work stays in dev environment

### **Enhanced Restrictions**

- **DevOps Override Removed**: No override permissions in production
- **Stricter Change Control**: More controlled deployment process
- **Emergency Focus**: Production support role for incident response

### **Additional Safety Measures**

- **Limited Create/Delete**: Fewer users can create or delete applications
- **Audit Trail**: All production changes are tracked and controlled
- **Emergency Procedures**: Dedicated support role for urgent issues

## Role Comparison - Production

| Capability          | Team Lead | DevOps    | Prod Support   |
| ------------------- | --------- | --------- | -------------- |
| View Applications   | ✅        | ✅        | ✅             |
| Create Applications | ✅        | ❌        | ❌             |
| Sync Applications   | ✅        | ✅        | ✅ (Emergency) |
| Delete Applications | ✅        | ❌        | ❌             |
| Override Settings   | ✅        | ❌        | ❌             |
| Repository Access   | ✅        | View Only | View Only      |
| Emergency Response  | ✅        | ✅        | ✅             |

## Production Best Practices

### **Change Management**

- All production changes require team lead approval
- DevOps executes planned deployments
- Emergency changes follow incident response procedures

### **Monitoring and Support**

- Production support monitors applications 24/7
- Immediate response capability for critical issues
- Escalation path to DevOps and Team Lead roles

### **Security and Compliance**

- Minimal required permissions for each role
- Clear separation between operational and development access
- Audit trail for all production activities

## Emergency Procedures

### **Incident Response**

1. **Production Support** identifies and assesses issues
2. **Emergency Sync** capability allows immediate response
3. **Escalation** to DevOps for complex deployments
4. **Team Lead** approval for major changes

This production role structure ensures operational safety while maintaining the ability to respond quickly to critical issues.
