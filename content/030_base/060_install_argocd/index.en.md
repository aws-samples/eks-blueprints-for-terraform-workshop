---
title: "Install Argo CD"
weight: 60
---

In this chapter, as a Platform Engineer ![Platform](/static/images/platform-task.png) you will install ArgoCD in the EKS Cluster.

::::expand{header="Why use Argo CD instead of Terraform to deploy Kubernetes resources?"}
While Terraform and Argo CD are both valuable infrastructure automation tools, they serve different purposes. Terraform excels at provisioning infrastructure components like VPCs, EKS clusters, and RDS instances. However, managing ongoing Kubernetes operations such as addon installation, workload deployments, and namespace creation can become complex with Terraform.

Argo CD specializes in continuous delivery for Kubernetes resources. It continuously monitors cluster state and automatically synchronizes any configuration drift back to the desired state defined in Git. This makes Argo CD well-suited for managing the lifecycle of Kubernetes applications and configurations.

The key difference is that Terraform performs one-time provisioning, while Argo CD provides continuous reconciliation. Unlike Terraform, Argo CD actively monitors for infrastructure changes and alerts when live state diverges from Git.
::::
