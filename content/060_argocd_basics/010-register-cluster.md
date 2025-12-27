---
title: "Register Cluster"
weight: 10
---

<!-- cspell:disable-next-line -->

<!-- ::video{id=DMJhqkbhjgo} -->

To deploy applications, ArgoCD needs to know which clusters it can target. We register clusters by creating Kubernetes secrets in the ArgoCD namespace.

We are going to register argocd-hub cluster with ArgoCD.

![Register Hub Cluster](/static/images/argobasics/register-hub-cluster-architecture.png)

### 1. Review Cluster Secret

Let's review the hub-argocd secret.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=true language=yaml highlightLines='7,14,15'}
apiVersion: v1
kind: Secret
metadata:
  name: hub
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    cluster-role: hub
  annotations:
    platform_url: https://git-codecommit.<<region>>.amazonaws.com/v1/repos/platform
    oci_registry_url: <<account id>>.dkr.ecr.<<region>>.amazonaws.com
type: Opaque
stringData:
  name: hub
  server: arn:aws:eks:<<region>>:<<account id>>:cluster/argocd-hub
:::
<!-- prettier-ignore-end -->

Key Components:
- Line 7: ArgoCD requires label "argocd.argoproj.io/secret-type: cluster" in secret to be recognized as a cluster 
- Line 14: Name of this cluster is hub. 
- Line 15: Server should set to ARN of the cluster
- **Authentication:** ArgoCD authenticates to the cluster using the EKS capability service-linked role(AmazonEKSCapabilityArgoCDRole), which has AmazonEKSClusterAdminPolicy configured through EKS access entries.

### 2. Register argocd-hub cluster

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
mkdir -p ~/environment/basics
cd ~/environment/basics
cp  $WORKSHOP_DIR/gitops/templates/register-cluster/register-hub-cluster-manual.yaml ~/environment/basics
kubectl apply -f register-hub-cluster-manual.yaml
:::
<!-- prettier-ignore-end -->

### 3. Validate Cluster 

You can view all clusters in the ArgoCD dashboard under Settings > Clusters.

![Validate Hub Cluster](/static/images/argobasics/register-hub-cluster.png)

 Note: Newly registered clusters show "Unknown" status until first deployment attempt.

### 4. Cross-Account & Private Clusters
This same approach works for clusters in different AWS accounts, regions, and even private clusters without public API endpoints. The managed ArgoCD service handles connectivity automatically.
