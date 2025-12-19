---
title: "Register Hub Cluster & Platform Repository"
weight: 10
---

### 1. Register Hub Cluster

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
mkdir -p ~/environment/basics
cd ~/environment/basics
cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/register-hub-cluster-manual.yaml ~/environment/basics
kubectl apply -f register-hub-cluster-manual.yaml
:::
<!-- prettier-ignore-end -->

### 2. Register Platform Repo

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-repo/register-platform-repo-manual.yaml ~/environment/basics
cd ~/environment/basics
kubectl apply -f register-platform-repo-manual.yaml
:::
<!-- prettier-ignore-end -->
