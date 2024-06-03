---
title: 'Blue/Green EKS Cluster Upgrade'
weight: 0
---

In the previous modules, we utilized the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller), which automatically created Load Balancers upon the creation of Ingress or Service Kubernetes objects. This controller generated an Application Load Balancer (ALB) for each Ingress resource, and in the case of an Ingress Group, it combined ingress rules from multiple ingresses and configured them within the same ALB by merging listeners and rules. The lifecycle of the Load Balancer was closely tied to one or more associated ingresses. If the Ingress object was deleted and there were no other ingresses in the group, the AWS Load Balancer Controller also removed the ALB.

However, this approach can pose challenges during a blue/green migration, as the load balancer needs to transition from the blue cluster to the green cluster. To address this, there are alternative solutions available. One solution involves maintaining the existing pattern while controlling the migration between clusters using DNS migration with [AWS Route53 weighted records](https://aws.amazon.com/blogs/containers/blue-green-or-canary-amazon-eks-clusters-migration-for-stateless-argocd-workloads/). Another approach could involve leveraging an [AWS Global Accelerator](https://aws.amazon.com/blogs/database/part-1-scale-applications-using-multi-region-amazon-eks-and-amazon-aurora-global-database/) in front of the ALB, providing a single entry point for end-users during the migration process.

In this workshop, we will be adopting a different approach that relies on existing load balancers created by Terraform instead of the load balancer controller.

![](/static/images/blue-green-alb-eks.png)