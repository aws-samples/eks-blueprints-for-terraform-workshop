---
title: 'Creating EKS cluster'
weight: 32
---

In this section, we are going to write a local module to deploy our EKS cluster.

Later, we will instantiate one or multiple versions of this module so we can create several EKS clusters in our VPC (the goal behind this is to be able to do blue.green cluster migration).

```bash
mkdir -p ~/environment/eks-blueprint/modules/eks_cluster
cd ~/environment/eks-blueprint/modules/eks_cluster
```

![Environment architecture diagram](/static/images/eks-blue.png)
