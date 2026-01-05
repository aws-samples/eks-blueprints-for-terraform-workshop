---
title: "Review ECR Registry"
weight: 20
---

Navigate to the AWS ECR console( On AWS console, enter ECR in the search bar and Select Elastic Contaner Registry )) to explore the container registry that stores both Helm charts and container images for the retail store application.

![ECR Repos](/static/images/git-ecr-repos/ecr-repos.png)

The ECR registry is organized into two main categories:

### 1. Platform Repositories
Purpose: Platform team Helm charts and tooling

Contents:
- Platform-level Helm charts used for cluster setup
- Infrastructure automation charts
- Shared platform components

Usage: These charts are used by the platform team to bootstrap and for automating cluster registration, repository registration, namespace creation, application deployment

### 2. Retail Store Repositories
Purpose: Application Helm charts and container images

![ECR Image](/static/images/git-ecr-repos/ecr-image.png)

This registry serves as the single source of truth for all deployment artifacts in our GitOps pipeline.
