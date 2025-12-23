---
title: "Register Hub Cluster"
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
