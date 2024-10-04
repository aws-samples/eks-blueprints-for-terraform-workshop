---
title: 'Kubernetes Addons'
weight: 60
---

![Kubernetes Addons](/static/images/kubernetes-addons.jpg)

An addon is software that provides supporting operational capabilities to Kubernetes applications. Addon software is typically built and maintained by the Kubernetes community, cloud providers like AWS, or third-party vendors. Amazon EKS automatically installs self-managed add-ons such as the Amazon VPC CNI plugin for Kubernetes, kube-proxy, and CoreDNS for every cluster. You have to install and manage all other addons.



GitOps Bridge maintains Argo CD [ApplicationSets](https://github.com/gitops-bridge-dev/gitops-bridge-argocd-control-plane-template/tree/main/bootstrap/control-plane/addons/aws) for various add-ons under the addons folder in its repository. As Kubernetes and EKS evolve, these ApplicationSets get updated by the GitOps Bridge project. Instead of writing our own ApplicationSet for each individual add-on, we will leverage the ones provided by GitOps Bridge. This avoids reinventing the wheel and allows us to benefit from the add-on ApplicationSets curated by the GitOps Bridge community.

This workshop utilizes a cloned copy of the GitOps Bridge ApplicationSets repository. **Organizations should consider cloning the ApplicationSets and then using them as-is or customizing them to meet their specific enterprise needs.**

::::expand{header="Why manage addons with Argo CD?"}
- GitOps based - Manifests are stored in Git, enabling version control, collaboration, and review.

- Automated sync - Argo CD auto-syncs the cluster state to match the Git repo. Provides continuous delivery.

- Rollback and auditability - Changes are tracked and can be easily rolled back. Improves reliability.

- Flexible lifecycle management - Upgrades, scaling, etc can be easily automated for addons.

- Multi-cluster capable - Can manage addons across multiple clusters in a consistent way.

- Health monitoring - Argo CD provides health status and alerts for addon deployments.
::::

::::expand{header="How is GitOps Bridge ApplicationSet configured?"}
The ApplicationSets provided by the GitOps Bridge can be overridden on per environment and per cluster basis.

For example, below is a side-by-side comparison of the GitOps Repo with override files and a snippet of the GitOps Bridge ApplicationSet. The configuration values are read from the default settings first. Then, any environment-specific settings will override the defaults. Finally, any cluster-specific settings will override both the default and environment values. For example, in the aws-load-balancer-controller addon, it gets default values from the folder `environments/default/addons/aws-load-balancer-controller`. Some values can be overwritten for the dev environment by adding `values.yaml` under `environments/dev/addons/aws-load-balancer-controller`. These can be overwritten for the my-cluster by adding values.yaml under `environments/clusters/my-cluster/addons/aws-load-balancer-controller`. Overriding the default values is optional - you can use the defaults if you don't need any customizations.

![Kubernetes Addons](/static/images/gitops-bridge-applicationset.png)
:::

