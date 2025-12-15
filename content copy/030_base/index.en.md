---
title: "Standalone Argo CD Deployment"
weight: 30
---

In this module, you will deploy a **self-contained ArgoCD** instance within a single Amazon EKS cluster. This standalone setup is ideal for managing resources within a single cluster, where Argo CD is co-located with the workloads and Kubernetes addons it manages.

![Standalone](/static/images/standalone-argocd.png)

To clarify responsibilities, we define two key roles: ![Platform](/static/images/platform-task.png) Platform Engineers and ![Platform](/static/images/developer-task.png) Developers.

- Platform Engineers are responsible for infrastructure provisioning—such as creating the VPC, EKS cluster, managing Kubernetes addons, and onboarding applications.

- Developers focus on defining and maintaining the workload-specific Kubernetes manifests, including Deployments, ConfigMaps, and other workload related resources
