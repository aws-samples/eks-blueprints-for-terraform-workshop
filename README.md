# EKS Blueprints for Terraform - Workshop

This is the repository for the [EKS Blueprints for Terraform Workshop](https://catalog.workshops.aws/eks-blueprints-terraform), which contains the workshop and associated assets.

This workshop helps you build a shared platform (Kubernetes multi-tenant) where multiple developer groups at an organization can consume and deploy workloads freely without the platform team being the bottleneck. We walk through the baseline setup of an EKS cluster, and gradually add add-ons to easily enhance its capabilities such as enabling Argo CD, Rollouts, GitOps and other common open-source add-ons. We then deploy a static website with proper SSL and domain via GitOps using Argo CD

It rely on [GitOps Bridge](https://github.com/gitops-bridge-dev/gitops-bridge) to provide a link between Terraform and Argo CD to bootstrap and configure your EKS clusters.

![](/static/images/gitops-bridge.png)

We will also walk through different architecture patterns like standalone 

![](/static/images/argocd-standalone.png)


or hub and spoke

![](/static/images/argocd-hub-spoke.png)


