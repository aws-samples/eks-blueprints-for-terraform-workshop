---
title: 'Self Manage ArgoCD'
weight: 70
---

In the "Install ArgoCD" chapter, ArgoCD was installed with default configuration with GitOps Bridge. ArgoCD is another addon. Can ArgoCD install itself and 
self manage? Yes it can. By having ArgoCD self-manage its own deployment and lifecycle through GitOps, it demonstrates the advantages and benefits of having addons managed by ArgoCD.

- GitOps based - Manifests are stored in Git, enabling version control, collaboration, and review.

- Automated sync - ArgoCD auto-syncs the cluster state to match the Git repo. Provides continuous delivery.

- Rollback and auditability - Changes are tracked and can be easily rolled back. Improves reliability.

- Flexible lifecycle management - Upgrades, scaling, etc can be easily automated for addons.

- Multi-cluster capable - Can manage addons across multiple clusters in a consistent way.

- Health monitoring - ArgoCD provides health status and alerts for addon deployments.

