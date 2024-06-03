---
title : "Summary"
weight : 100
---


You have successfully completed this workshop. In this workshop, we learned how EKS Blueprints makes it easy to deploy clusters using IaC Terraform.  We learned how to onboard a team from a platform perspective.  We also acted as the development team and deployed our first workload using Helm while practicing GitOps with ArgoCD.

We see how we can leverage Argo Rollout to do application blue/green deployment.

We make use of Karpenter to allow our application to define and use the resources it needs while having the right EC2 nodes at the right time, binpacking our nodes, and keeping the cost of the cluster low.

We see how we can rely on Spot instances to even reduce our cluster cost and use Kubecost to optimize our workloads.

Finally, we focused on Day2 Operations, and how we can automate Blue/Green EKS cluster migration for doing updates.

We hope you enjoy this workshop and know that the EKS Blueprint project is open-source. You can learn more at: https://github.com/aws-ia/terraform-aws-eks-blueprints