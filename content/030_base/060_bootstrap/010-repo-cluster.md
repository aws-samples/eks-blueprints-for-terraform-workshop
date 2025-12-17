---
title: "Register Hub Cluster & Platform Repository"
weight: 10
---

### 1. Register Hub Cluster

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-hub-cluster.yaml ~/environment/basics
cd ~/environment/basics
kubectl apply -f register-hub-cluster.yaml
:::
<!-- prettier-ignore-end -->

### 2. Register Platform Repo

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-platform-repo.yaml ~/environment/basics
cd ~/environment/basics
kubectl apply -f register-platform-repo.yaml
:::
<!-- prettier-ignore-end -->
