---
title: "Install AWS Load Balancer Controller & Karpenter addons"
weight: 50
---

### 1. Create IAM roles for addons

Many Kubernetes addons require authenticated communication with AWS APIs to seamlessly integrate Kubernetes with AWS infrastructure and services. We need to configure proper IAM roles and policies to grant the addons the necessary permissions. For example, the AWS Load Balancer Controller addon interacts with EC2 APIs to provision Network Load Balancers (NLBs) and Application Load Balancers (ALBs). Similarly, the Karpenter autoscaler interacts with EC2 APIs to dynamically provision and terminate compute resources like EC2 instances based on cluster needs.

![addons-lb-role](/static/images/addon-lb-role.png)

Instead of manually creating these IAM roles, we can use the Terraform EKS Blueprints addons module [eks_blueprints_addons](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest) to automatically provision least privilege roles for each addon.

This module allows both installing the addons and creating their IAM roles. However, we only want it to create the IAM roles, not deploy the addons themselves. The installation of the addons onto the EKS cluster is done by Argo CD.

Using EKS Blueprint Addons module improves security and reduces complexity.

We can configure the Terraform module to create only the required AWS resources but not the kubernetes resources (as we prefer as a best practice to let Argo CD talk to Kubernetes) by setting **create_kubernetes_resources = false** as set in line 15 below.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml highlightLines='15'}
cat <<'EOF' >> ~/environment/hub/main.tf
################################################################################
# EKS Blueprints Addons
################################################################################
module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16.3"

  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_version = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Using GitOps Bridge

  create_kubernetes_resources = false

  # EKS Blueprints Addons

  enable_cert_manager = local.aws_addons.enable_cert_manager
  enable_aws_efs_csi_driver = local.aws_addons.enable_aws_efs_csi_driver
  enable_aws_fsx_csi_driver = local.aws_addons.enable_aws_fsx_csi_driver
  enable_aws_cloudwatch_metrics = local.aws_addons.enable_aws_cloudwatch_metrics
  enable_aws_privateca_issuer = local.aws_addons.enable_aws_privateca_issuer
  enable_cluster_autoscaler = local.aws_addons.enable_cluster_autoscaler
  enable_external_dns = local.aws_addons.enable_external_dns

  #using pod identity for external secrets we don't need this
  #enable_external_secrets = local.aws_addons.enable_external_secrets

  #using pod identity for load balancer controller we don't need this
  #enable_aws_load_balancer_controller = local.aws_addons.enable_aws_load_balancer_controller
  enable_fargate_fluentbit = local.aws_addons.enable_fargate_fluentbit
  enable_aws_for_fluentbit = local.aws_addons.enable_aws_for_fluentbit
  enable_aws_node_termination_handler = local.aws_addons.enable_aws_node_termination_handler

  #using pod identity for karpenter we don't need this
  #enable_karpenter = local.aws_addons.enable_karpenter
  enable_velero = local.aws_addons.enable_velero
  enable_aws_gateway_api_controller = local.aws_addons.enable_aws_gateway_api_controller

  tags = local.tags
}
EOF
:::
<!-- prettier-ignore-end -->

For some of the addons, we prefer to rely on EKS Pod Identity rather than IRSA. As the EKS blueprints Addons have not yet implemented Pod Identity, we deactivate it to use the EKS pod identity module instead:

```bash
cp $BASE_DIR/solution/hub/pod-identity.tf /home/ec2-user/environment/hub
```

This file defines several roles that will be used by some of the addons. Here, the Load balancer controller will use:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='0'}
module "aws_lb_controller_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name = "aws-lbc"

  attach_aws_lb_controller_policy = true


  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name = module.eks.cluster_name
      namespace       = local.aws_load_balancer_controller.namespace
      service_account = local.aws_load_balancer_controller.service_account
    }
  }

  tags = local.tags
}
:::
<!-- prettier-ignore-end -->

This will call the EKS API to make the association between the IAM role that will be created and the Kubernetes namespace and service_account.

The file also creates roles for:

- External Secret operator
- CloudWatch Observability
- Kyverno Policy Reporter
- EBS CSI Driver
- AWS Load Balancer controller
- Karpenter
- CNI Metrics helper

This means we can easily activate these addons through GitOps Bridge afterwards.

### 2. Provide addon IAM role to Argo CD

We use the Terraform EKS Blueprints addons module to create AWS resources for EKS addons. These resource identifiers need to be provided to Argo CD, which handles actually installing the addons on the Kubernetes cluster. In this case, the IAM roles for the load balancer controller will be set on the service accounts of the addon by Argo CD.

The EKS addons module makes it easy to access the created AWS resource identifiers using the "gitops_metadata" output. This output is passed to the GitOps bridge, which sets annotations on the cluster. The annotations contain the proper info and can be accessed by the addon ApplicationSets deployed by Argo CD.

```bash
sed -i "s/#enableaddonmetadata//g" ~/environment/hub/main.tf
```

Updated change highlighted below.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='5-5'}
locals{
  .
  .
  addons_metadata = merge(
    module.eks_blueprints_addons.gitops_metadata,
    {
     aws_cluster_name = module.eks.cluster_name
     .
    },
  .
}
:::
<!-- prettier-ignore-end -->

### 3. More about GitOps Bridge v2

The goal of this chapter is to demonstrate how easy it can be to install an addon on a Kubernetes cluster using Argo CD. We will show how a simple change to the Git repository can trigger Argo CD to deploy and manage an addon in an automated way.

With GitOps Bridge v2, we rely on a Helm Chart to create the addons ApplicationSets. This Generic Helm chart is configured with a value file, that we can find here:

```bash
code $GITOPS_DIR/addons/charts/gitops-bridge/values.yaml
```

This file contains all the addons, with their versions, and configurations that we may want to enable in the cluster.

For example, if we search for **load-balancer-controller** in this file we should get this output:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='14,15,16'}

  aws_load_balancer_controller:
    enabled: false
    releaseName: aws-load-balancer-controller
    aws_load_balancer_controller:
    chart: aws-load-balancer-controller
    repoUrl: https://aws.github.io/eks-charts
    targetRevision: "1.8.1"
    namespace: '.metadata.annotations.aws_load_balancer_controller_namespace'
    annotationsAppSet:
      argocd.argoproj.io/sync-wave: '-1'
    selector:
      matchExpressions:
        - key: enable_aws_load_balancer_controller
          operator: In
          values: ['true']
    values:
      vpcId: '{{.metadata.annotations.aws_vpc_id}}'
      clusterName: '{{.metadata.annotations.aws_cluster_name}}'
      serviceAccount:
        name: '{{.metadata.annotations.aws_load_balancer_controller_service_account}}'
:::
<!-- prettier-ignore-end -->

We can see that this addon will be installed if we provide the label **enable_aws_load_balancer_controller** with **true** value.

If we remember how we created the addons-applicationset, we have a way to pass several valueFiles that can be used to change the default value depending on the context:

```bash
cat $GITOPS_DIR/platform/bootstrap/addons-applicationset.yaml | grep value
```

That should output:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='9'}

      values:
      - ref: values
        path: '{{.metadata.annotations.addons_repo_basepath}}charts/{{.values.addonChart}}'
          valuesObject:
          valueFiles:
            - '$values/{{.metadata.annotations.addons_repo_basepath}}default/addons/{{.values.addonChart}}/values.yaml'
            - '$values/{{.metadata.annotations.addons_repo_basepath}}environments/{{.metadata.labels.environment}}/addons/{{.values.addonChart}}/values.yaml'
            - '$values/{{.metadata.annotations.addons_repo_basepath}}clusters/{{.name}}/addons/{{.values.addonChart}}/values.yaml'
            - '$values/{{.metadata.annotations.addons_repo_basepath}}tenants/{{.metadata.labels.tenant}}/default/addons/{{.values.addonChart}}/values.yaml'
            - '$values/{{.metadata.annotations.addons_repo_basepath}}tenants/{{.metadata.labels.tenant}}/environments/{{.metadata.labels.environment}}/addons/{{.values.addonChart}}/values.yaml'
            - '$values/{{.metadata.annotations.addons_repo_basepath}}tenants/{{.metadata.labels.tenant}}/clusters/{{.name}}/addons/{{.values.addonChart}}/values.yaml'
:::
<!-- prettier-ignore-end -->

This means we can have custom values by **environment**, **clusters**, or by **tenants**.

In this case, we are going to update the highlighted one, so at the **cluster** level.

### 4. Enable load-balancer-controller for our cluster.

```bash
cat <<'EOF' >> ~/environment/hub/terraform.tfvars
addons = {
    enable_aws_load_balancer_controller = "true"
    enable_karpenter = "true"
}
EOF
```

We can refresh the application in Argo CD UI.

### 5. Apply Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply --auto-approve
```

:::alert{header="Important" type="info"}
This process will take some time, as we are creating with Terraform all the pre-requisites for our addons
:::

### 6. Verify the load balancer deployment

We can accelerate the argocd reconciliation with manual sync:

```bash
argocd app sync argocd/cluster-addons
```

The Argo CD dashboard should have a load balancer application.

![hubcluster-lb-addon](/static/images/hubcluster-lb-addon.png)

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller --context hub-cluster
```

Expected output:

```
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           2m47s
```

### 6. Verify the Karpenter deployment

We can accelerate the argocd reconciliation with manual sync:

```bash
kubectl get deployment -n kube-system karpenter --context hub-cluster
```

Expected output:

```
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   2/2     2            2           3m33s
```

### 7. Troubleshoot

In case of issues, we can check the logs of different components. Generally the ApplicationSet controller is a good choice:

```bash
kubectl stern -n argocd applicationset --tail=10
```

This command will show us the logs of the controller. We can use `Crtl-C` to quit the tail of the logs.
