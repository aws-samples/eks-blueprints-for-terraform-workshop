---
title: "Bootstrap"
weight: 20
---

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

cp -r /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/bootstrap/bootstrap.yaml  ~/environment/basics
cd ~/environment/basics
kubectl apply -f bootstrap.yaml
:::
<!-- prettier-ignore-end -->
