---
title: 'Self Manage Argo CD'
weight: 70
---

In the "Install Argo CD" chapter, Argo CD was installed with default configuration with GitOps Bridge. Argo CD is another addon. Can Argo CD install itself and 
self manage? Yes it can. By having Argo CD self-manage its own deployment and lifecycle through GitOps, it demonstrates the advantages and benefits of having addons managed by Argo CD.

- GitOps based - Manifests are stored in Git, enabling version control, collaboration, and review.

- Automated sync - Argo CD auto-syncs the cluster state to match the Git repo. Provides continuous delivery.

- Rollback and auditability - Changes are tracked and can be easily rolled back. Improves reliability.

- Flexible lifecycle management - Upgrades, scaling, etc can be easily automated for addons.

- Multi-cluster capable - Can manage addons across multiple clusters in a consistent way.

- Health monitoring - Argo CD provides health status and alerts for addon deployments.

