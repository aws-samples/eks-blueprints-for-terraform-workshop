---
title: "ArgoCD Authentication Setup"
weight: 35
---

This chapter covers how to configure authentication for Amazon EKS managed ArgoCD using AWS Identity Center (IDC). You'll learn about user management, role-based access control, and security best practices for ArgoCD authentication.

### Why Users Need to Login to ArgoCD

Users authenticate to ArgoCD to manage and interact with various ArgoCD objects and resources:

Manage Core ArgoCD Objects
- Applications: Deploy and manage Kubernetes applications using GitOps
- ApplicationSets: Manage multiple applications across clusters and environments
- Projects: Organize and scope access to applications and resources
- Repositories: Connect to Git repositories containing application manifests
- Clusters: Register and manage target Kubernetes clusters for deployments

Configure Objects
- Certificates: Manage TLS certificates for secure connections

Operational Tasks
- Application Sync: Deploy changes from Git to Kubernetes clusters
- Health Monitoring: Monitor application health and status
- Resource Management: View and manage Kubernetes resources
- Troubleshooting: Debug deployment issues and view logs

### ArgoCD Authentication Concepts

Amazon EKS managed ArgoCD does not provide the ability to create local users. Instead, it integrates with AWS Identity Center (IDC) for user authentication.

Key Points
- No Local Users: ArgoCD cannot create or manage users directly
- IDC Integration: All user authentication flows through AWS Identity Center
- External Integration: IDC can integrate with existing identity providers like Active Directory or external providers like Ping, Okta etc

## Workshop Setup

For this workshop, we have:

- Created a new AWS Identity Center instance
- Not integrated with external identity providers
- Created users and groups within IDC


This chapter focuses on user authentication to ArgoCD (how users log in), not on how ArgoCD accesses AWS services and Kubernetes Clusters. 


