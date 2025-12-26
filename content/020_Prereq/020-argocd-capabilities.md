---
title: "ArgoCD Capabilites"
weight: 20
---

::video{id=RXpc2xS8B24 }

### 1. What is it? 
EKS managed ArgoCD capability where AWS handles the operational overhead of running ArgoCD for you.

### 2. Key Benefits:
- **Fully managed**: AWS installs, scales, and maintains the Argo CD instance
- **Easy setup**: Enable via Console, CLI, Terraform, or CloudFormation
- **Focus on applications**: You only manage Application, ApplicationSet, and AppProject resources

### 3. How it works:
1. AWS creates and manages Argo CD components (API server, repo server, application controller, Redis) in their managed account
2. CRDs (Application, ApplicationSet, AppProject) get installed in your EKS cluster
3. You create and manage your ArgoCD applications in your cluster

![Platform](/static/images/prereq/eks-argocd-capability.png) EKS Managed ArgoCD Capability

You can find Comparing EKS Capability for Argo CD to self-managed ArgoCD [here](https://docs.aws.amazon.com/eks/latest/userguide/argocd-comparison.html).
