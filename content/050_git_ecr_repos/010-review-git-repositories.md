---
title: "Review Git Repositories"
weight: 10
---

Navigate to the AWS CodeCommit console( On AWS console, enter CodeCommit in the search bar ) to explore the three repositories that support our GitOps workflow.

We have created 3 repositories to show separation of concerns:
- Platform teams (platform repo) to manage infrastructure independently
- Development teams (retail-store-app) to focus on application code  
- DevOps teams (retail-store-config) to control deployment configurations. This repo will be only accessible to those responsible for configuring the application.

![CodeCommit Repos](/static/images/git-ecr-repos/git-repos.png)

### 1. Platform Repository (platform)

Purpose: Platform team automation and infrastructure management

Contents:
- Cluster automation scripts
- Repository and team registration metadata
- Platform-level Helm charts (deployed versions pushed to ECR)

Ownership: Platform team responsible for infrastructure and cluster lifecycle

Usage: Automates the registration of clusters, repositories, ArgoCD projects, namespaces and deployment of applications

### 2. Retail Store App Repository (retail-store-app)

Purpose: Application development and source code management

Contents:
- Microservice source code (catalog, cart, checkout, orders, ui)
- Application-level Helm charts
- Docker image build configurations

Ownership: Development teams responsible for application code and containerization

Note: This repository is shown for completeness. We don't modify it during this workshop as our focus is on GitOps configuration management.

### 3. Retail Store Config Repository (retail-store-config)

Purpose: Environment-specific configuration and deployment values

Contents:
- Helm chart values for different environments (dev, prod)
- Environment-specific configurations
- ArgoCD Application manifests

Ownership: DevOps teams manage environment configurations

Usage: In upcoming chapters, we'll add and modify values for dev and prod environments through this repository.




