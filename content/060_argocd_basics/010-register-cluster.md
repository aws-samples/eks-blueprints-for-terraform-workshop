---
title: "Register Cluster"
weight: 10
---

<!-- cspell:disable-next-line -->

::video{id=DMJhqkbhjgo}

## Cluster Registration with ArgoCD

To deploy applications, ArgoCD needs to know which clusters it can target. We register clusters by creating Kubernetes secrets in the ArgoCD namespace.

Key Components:
- **Server field**: Points to the EKS cluster ARN (not the API endpoint URL)
- **Authentication**: Uses the EKS capability service-linked role with administrator access
- **State**: Newly registered clusters show "Unknown" until first deployment

Cross-Account & Private Clusters:
This same approach works for clusters in different AWS accounts, regions, and even private clusters without public API endpoints. The managed ArgoCD service handles 
connectivity automatically.

Once registered, you can view all clusters in the ArgoCD dashboard under Settings > Clusters.