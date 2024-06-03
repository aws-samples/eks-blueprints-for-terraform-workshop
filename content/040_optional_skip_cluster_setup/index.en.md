---
title : "[Optional] - Skip Manual Cluster Provisioning"
weight : 30
---

If you followed the manual **Provision Amazon EKS Cluster** module and you have your EKS cluster and ArgoCD deployed, you can skip this section and go straight to the Next Lab.

:button[Go to Next Lab]{variant="primary" href="/050-dev-team-deploy-workload/"}

## Deploy from our template

In case you have an error somewhere or want to skip the manual setup of the previous section, you can execute the following commands to retrieve and adjust the EKS Blueprint Terraform project from a working copy zip we provide for you:

### 1. Get a code from a backup

```bash
cp -r ~/environment/code-eks-blueprint ~/environment/eks-blueprint
```

### 2. Fork the Github workload repository

Fork this repository https://github.com/aws-samples/eks-blueprints-workloads.git and export your Github login: 

```
export GITHUB_USER=<YOUR_GITHUB_USER>
```

### 3. Then configure the Terraform configuration file: 

```bash
envsubst < ~/environment/eks-blueprint/terraform.tfvars.example > ~/environment/eks-blueprint/terraform.tfvars
```

::alert[If you already created Terraform resources, you can either use the zip as valid files and try to fix any issues you may have, If you delete your directory and apply the zip, you may have Terraform resources name conflicts; in this case, it may be easier to rename the `environment` in the `terraform.tfvars` file ]{header="Important"}

Then check that the file is correctly configured:

```bash
c9 open ~/environment/eks-blueprint/terraform.tfvars
```

### 4. Deploy the environment

```bash
cd ~/environment/eks-blueprint/environment
terraform init
terraform apply
```

### 5. Deploy our EKS cluster

```bash
cd ~/environment/eks-blueprint/eks-blue
terraform init
terraform apply
```

::alert[If you want to know more, go to the [Manual provisioning steps](../030-provision-eks-cluster/01-environment)]{header="Important"}
