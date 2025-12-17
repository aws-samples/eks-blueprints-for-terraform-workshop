---
title: "Create Cluster & Repository"
weight: 10
---

### 1. Register Hub Cluster 

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

cp -r /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/platform-repo.yaml ~/environment/basics
cd ${GITOPS_DIR}/basics
kubectl apply -f platform-repo.yaml
:::
<!-- prettier-ignore-end -->