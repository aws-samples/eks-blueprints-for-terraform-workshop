---
title: "Install Argo CD"
weight: 50
---

Argo CD is a declarative continuous delivery tool for Kubernetes.

::::expand{header="What is GitOps?"}
[GitOps](https://www.cncf.io/blog/2021/09/28/gitops-101-whats-it-all-about/) is an operational framework that takes DevOps best practices and applies them to infrastructure automation. GitOps uses Git as the single source of truth for infrastructure and application definitions. Infrastructure changes are made by merging pull requests to Git repositories rather than making changes directly in the runtime environment.
::::

::::expand{header="What is Argo CD?"}
[Argo CD](https://argo-cd.readthedocs.io/en/stable/) is an open source GitOps continuous delivery tool designed specifically for Kubernetes environments.
::::

::::expand{header="Why use Argo CD instead of Terraform to deploy Kubernetes resources?"}
While Terraform and Argo CD are both valuable infrastructure automation tools, they serve different purposes. Terraform excels at provisioning infrastructure components like VPCs, EKS clusters, and RDS instances. However, managing ongoing Kubernetes operations like addon installation, workload deployments, and namespace creation can become complex with Terraform.

Argo CD specializes in continuous delivery for Kubernetes resources. It continuously monitors cluster state and automatically synchronizes any configuration drift back to the desired state defined in Git. This makes Argo CD well-suited for managing the lifecycle of Kubernetes applications and configurations.

The key difference is that Terraform performs one-time provisioning, while Argo CD provides continuous reconciliation. Unlike Terraform, Argo CD actively monitors for infrastructure changes and alerts when live state diverges from Git.
::::

::::expand{header="Why GitOps Bridge?"}
While Argo CD excels at continuous delivery for Kubernetes resources, it needs integration with cloud providers like AWS to manage certain cluster addons and services. [GitOps Bridge](https://github.com/gitops-bridge-dev/gitops-bridge) facilitates this integration by:

- Providing pre-configured IAM roles for addons like Karpenter and load balancers to access AWS services

- Offering an interface to manage labels and annotations on cloud resources

- Automating the initial Argo CD installation process

- Enabling cluster bootstrap using the "App of ApplicationSets" pattern

- Simplifying self-management of Argo CD configuration

- Including sample ApplicationSets for addons that can be customized for specific needs
  ::::
