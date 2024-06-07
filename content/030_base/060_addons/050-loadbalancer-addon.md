---
title: 'Install AWS Load Balancer Controller addon'
weight: 50
---

The goal of this chapter is to demonstrate how easy it can be to install an addon on a Kubernetes cluster using ArgoCD. The steps will show you how a simple change to the Git repository can trigger ArgoCD to deploy and manage an addon in an automated way.

In the previous chapter, we created ApplicationSets for various add-ons, but they did not generate any Applications yet because the conditions were not met. For example, looking at the `assets/platform/addons/applicationset/aws/addons-aws-load-balancer-controller-appset.yaml` file in your Git repo, the loadbalancer ApplicationSet requires clusters to have the label `enable_aws_load_balancer_controller=true`. Currently, your only cluster is hub-cluster and it does not have that label.

```bash
c9 open ~/environment/wgit/assets/platform/addons/applicationset/aws/addons-aws-load-balancer-controller-appset.yaml
```

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='7-10'}
generators:
  - clusters:
      selector:
        matchExpressions:
          .
          .
          - key: enable_aws_load_balancer_controller
            operator: In
            values:
              - 'true'
:::

### 1. Set load balancer label in terraform variables

```bash
sed -i "s/enable_aws_load_balancer_controller = false/enable_aws_load_balancer_controller = true/g" ~/environment/terraform.tfvars
```
The above code snippet will uncomment the label `enable_aws_load_balancer_controller=true` in the `~/environment/terraform.tfvars` file, as shown highlighted below.

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='6-6'}
...
addons = {
    ...
    enable_aws_load_balancer_controller = true
}
    
:::

### 2. Create IAM roles for addon

Several addons use the AWS APIs to seamlessly integrate Kubernetes with AWS infrastructure and services. Proper IAM roles and policies or other AWS ressources may need to be configured to grant the addons necessary permissions.
For example loadbalancer interact with EC2 AWS APIs to provision NLB/ALB and Karpenter interact with EC2 AWS APIs to provision compute (EC2/Fargate)

![addons-lb-role](/static/images/addon-lb-role.png)


Instead of manually creating these IAM roles, the Terraform EKS Blueprints addons module [eks_blueprints_addons](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest) can automatically provision least privilege roles for each addon. 

This module allows both installing the addons and creating their IAM roles. However, we only want it to create the IAM roles, not deploy the addons themselves. The installation of the addons onto the EKS cluster is done by ArgoCD

Using EKS Blueprint Addons module improves security and reduces complexity.

You can configure the Terraform module to create only the required AWS resources but not the kubernetes resources (as we prefer as a best practice to let ArgoCD talk to Kubernetes) by setting **create_kubernetes_resources = false** as set in line 12 below.


:::code{showCopyAction=true showLineNumbers=false language=yaml highlightLines='12'}
cat <<'EOF' >> ~/environment/hub/main.tf
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Using GitOps Bridge
  create_kubernetes_resources = false

  # EKS Blueprints Addons
  enable_cert_manager                 = try(local.aws_addons.enable_cert_manager, false)
  enable_aws_efs_csi_driver           = try(local.aws_addons.enable_aws_efs_csi_driver, false)
  enable_aws_fsx_csi_driver           = try(local.aws_addons.enable_aws_fsx_csi_driver, false)
  enable_aws_cloudwatch_metrics       = try(local.aws_addons.enable_aws_cloudwatch_metrics, false)
  enable_aws_privateca_issuer         = try(local.aws_addons.enable_aws_privateca_issuer, false)
  enable_cluster_autoscaler           = try(local.aws_addons.enable_cluster_autoscaler, false)
  enable_external_dns                 = try(local.aws_addons.enable_external_dns, false)
  enable_external_secrets             = try(local.aws_addons.enable_external_secrets, false)
  enable_aws_load_balancer_controller = try(local.aws_addons.enable_aws_load_balancer_controller, false)
  enable_fargate_fluentbit            = try(local.aws_addons.enable_fargate_fluentbit, false)
  enable_aws_for_fluentbit            = try(local.aws_addons.enable_aws_for_fluentbit, false)
  enable_aws_node_termination_handler = try(local.aws_addons.enable_aws_node_termination_handler, false)
  enable_karpenter                    = try(local.aws_addons.enable_karpenter, false)
  enable_velero                       = try(local.aws_addons.enable_velero, false)
  enable_aws_gateway_api_controller   = try(local.aws_addons.enable_aws_gateway_api_controller, false)

  tags = local.tags
}
EOF
:::


### 3. Provide addon IAM role to ArgoCD


We use the Terraform EKS Blueprints addons module to create AWS ressources for EKS addons. These resources identifiers need to be provided to ArgoCD, which handles actually installing the addons on the Kubernetes cluster. In this case, the IAM roles for the load balancer controller will be set on the service accounts of the addon by ArgoCD. 

The EKS addons module makes it easy to access the created AWS ressources identifiers using the "gitops_metadata" output. This output is passed to the GitOps bridge, which sets annotations on the cluster. The annotations contain the proper info and can be accessed by the addon ApplicationSets deployed by ArgoCD.

```bash
sed -i "s/#enableaddonmetadata//g" ~/environment/hub/main.tf
```
Updated change highlighted below.

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='5-5'}
locals{
  .
  .
  addons_metadata = merge(
     module.eks_blueprints_addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
  .
  .
:::

### 4. Apply Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply --auto-approve
```

The ArgoCD dashboard should have a load balancer application.

![hubcluster-lb-addon](/static/images/hubcluster-lb-addon.png)

### 5. Verify the load balancer deployment

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller --context hub
```
::::expand{header="Where is the IAM load balancer role, created by the EKS Blueprint addon module, provided to ArgoCD?"}
You can find it in the hub cluster's 'aws_load_balancer_controller_iam_role_arn' annotation on the ArgoCD dashboard.

![hubcluster-lb-arn](/static/images/lb-arn.png)

::::
