---
title: 'Install ArgoCD'
weight: 50
---

ArgoCD is a declarative continuous delivery tool for Kubernetes. 

::::expand{header="What is GitOps?"}
[GitOps](https://www.cncf.io/blog/2021/09/28/gitops-101-whats-it-all-about/) is a way of managing infrastructure and applications using Git as the single source of truth. GitOps watches this Git repository and automatically applies any changes to make the actual state match the desired state in Git
::::

::::expand{header="What is ArgoCD?"}
[ArgoCD](https://argo-cd.readthedocs.io/en/stable/) is an open source GitOps continuous delivery tool for Kubernetes.
::::

::::expand{header="Why use ArgoCD instead of Terraform for infrastructure automation?"}
Terraform and ArgoCD are complementary tools for infrastructure automation. Terraform excels at provisioning infrastructure like VPCs, EKS clusters, RDS instances, etc. However, it can become complex when trying to use it for ongoing infrastructure operations like managing addons, deploying workloads, creating namespaces, etc. 

ArgoCD specializes in continuous delivery for Kubernetes. It monitors the live state of a cluster and automatically syncs any configuration drift back to the desired state defined in Git. This makes ArgoCD well-suited for deploying applications and managing configuration for a Kubernetes cluster.

A key difference is that Terraform performs one-time provisioning, while ArgoCD provides continuous reconciliation. Terraform does not monitor or alert on infrastructure changes after the initial provisioning. ArgoCD gives real-time alerts if the live state drifts from the desired state in Git.
::::

::::expand{header="Why GitOps Bridge?"}
 ArgoCD specializes in continuous delivery for Kubernetes, but requires integration with infrastructure providers like AWS to manage some cluster addons and services. [GitOps Bridge](https://github.com/gitops-bridge-dev/gitops-bridge) assists with this by:

- It provides provisioned IAM roles for addons like Karpenter and load balancers to access AWS accounts

- An interface to update labels and annotations on cloud resources

- Automated initial installation of ArgoCD

- Creation of root applications for an "App of Apps" pattern 

- Simple Self-management of the ArgoCD configuration

- Sample ApplicationSets for addons to customize for your needs
::::
