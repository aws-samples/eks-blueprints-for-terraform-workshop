---
title: "Onboard Dev team"
weight: 10
---

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/bootstrap/register-team.yaml $GITOPS_DIR/platform/bootstrap
cd ${GITOPS_DIR}/platform/bootstrap
git add .
git commit -m "add bootstrap repo registration"
git push 
:::
<!-- prettier-ignore-end -->

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
mkdir -p ~/environment/gitops-repos/platform/register-team/retail-store
cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/retail-store-environments.yaml ~/environment/gitops-repos/platform/register-team/retail-store/environments.yaml
mkdir -p ~/environment/gitops-repos/platform/register-team/retail-store/namespace
cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/namespace/* ~/environment/gitops-repos/platform/register-team/retail-store/namespace
mkdir -p ~/environment/gitops-repos/platform/register-team/retail-store/project
cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/project/* ~/environment/gitops-repos/platform/register-team/retail-store/project
cd ${GITOPS_DIR}/platform
git add .
git commit -m "add bootstrap repo registration"
git push 
:::
<!-- prettier-ignore-end -->
