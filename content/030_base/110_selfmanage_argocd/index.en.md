---
title: "Self Manage Argo CD"
weight: 110
---

In the "Install Argo CD" chapter, we installed Argo CD with a default configuration using GitOps Bridge. Since Argo CD is itself an addon, we can leverage its own capabilities for self-management. By having Argo CD manage its own deployment and lifecycle through GitOps, we demonstrate several key benefits of addon management:

- GitOps-based configuration: All manifests are stored in Git, enabling version control, collaboration, and review processes.

- Automated synchronization: Argo CD continuously syncs cluster state to match the Git repository, providing true continuous delivery.

- Rollback capability and audit trail: Changes are tracked and can be easily rolled back, improving overall reliability.

- Flexible lifecycle management: Upgrades, scaling, and other operations can be easily automated.

- Multi-cluster support: Addons can be managed consistently across multiple clusters.

- Health monitoring: Argo CD provides health status and alerts for addon deployments.

By implementing self-management for Argo CD through GitOps practices, we establish a foundation for managing all cluster addons in a consistent and automated way.
