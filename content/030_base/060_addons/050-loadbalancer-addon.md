---
title: "Install AWS Load Balancer Controller addon"
weight: 50
---

### 1. Create IAM roles for addon

Many Kubernetes addons require authenticated communication with AWS APIs to seamlessly integrate Kubernetes with AWS infrastructure and services. Proper IAM roles and policies must be configured to grant the addons the necessary permissions. For example, the AWS Load Balancer Controller addon interacts with EC2 APIs to provision Network Load Balancers (NLBs) and Application Load Balancers (ALBs). Similarly, the Karpenter autoscaler interacts with EC2 APIs to dynamically provision and terminate compute resources like EC2 instances based on cluster needs.

![addons-lb-role](/static/images/addon-lb-role.png)

Instead of manually creating these IAM roles, the Terraform EKS Blueprints addons module [eks_blueprints_addons](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest) can automatically provision least privilege roles for each addon.

This module allows both installing the addons and creating their IAM roles. However, we only want it to create the IAM roles, not deploy the addons themselves. The installation of the addons onto the EKS cluster is done by Argo CD

Using EKS Blueprint Addons module improves security and reduces complexity.

You can configure the Terraform module to create only the required AWS resources but not the kubernetes resources (as we prefer as a best practice to let Argo CD talk to Kubernetes) by setting **create_kubernetes_resources = false** as set in line 12 below.

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

# using pod identity for external secrets we don't need this

#enable_external_secrets = local.aws_addons.enable_external_secrets

# using pod identity for load balancer controller we don't need this

#enable_aws_load_balancer_controller = local.aws_addons.enable_aws_load_balancer_controller
enable_fargate_fluentbit = local.aws_addons.enable_fargate_fluentbit
enable_aws_for_fluentbit = local.aws_addons.enable_aws_for_fluentbit
enable_aws_node_termination_handler = local.aws_addons.enable_aws_node_termination_handler

# using pod identity for karpenter we don't need this

#enable_karpenter = local.aws_addons.enable_karpenter
enable_velero = local.aws_addons.enable_velero
enable_aws_gateway_api_controller = local.aws_addons.enable_aws_gateway_api_controller

tags = local.tags
}
EOF
:::

For Some of the addons, we prefer to rely on EKS Pod Identity, instead of IRSA. Has the EKS blueprints Addons, did not yet implement the Pod Identity, we deactivate it to use the EKS pod identity module instead:

```bash
cp $BASE_DIR/solution/hub/pod-identity.tf /home/ec2-user/environment/hub
```

This file defines several roles that will be used by some of the addons, here Load balancer controller will uses :

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

This Will call the EKS API to make the association between the IAM role that will be created and the Kubernetes namespace and service_account

The file also create roles for:

- External Secret operator
- CloudWatch Observability
- Kyverno Policy Reporter
- EBS CSI Driver
- AWS Load Balancer controller
- Karpenter
- CNI Metrics helper

That mean that we could easily activate theses addons through GitOps Bridge afterwards.

### 2. Provide addon IAM role to Argo CD

We use the Terraform EKS Blueprints addons module to create AWS resources for EKS addons. These resources identifiers need to be provided to Argo CD, which handles actually installing the addons on the Kubernetes cluster. In this case, the IAM roles for the load balancer controller will be set on the service accounts of the addon by Argo CD.

The EKS addons module makes it easy to access the created AWS resources identifiers using the "gitops_metadata" output. This output is passed to the GitOps bridge, which sets annotations on the cluster. The annotations contain the proper info and can be accessed by the addon ApplicationSets deployed by Argo CD.

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



### 3. More about GitOps Bridge v2

The goal of this chapter is to demonstrate how easy it can be to install an addon on a Kubernetes cluster using Argo CD. The steps will show you how a simple change to the Git repository can trigger Argo CD to deploy and manage an addon in an automated way.

With GitOps Bridge v2, we rely on a Helm Charts to create the addons ApplicationSets. This Generic Helm chart is configured with a value file, that you can find here: 

```bash
code $GITOPS_DIR/addons/charts/gitops-bridge/values.yaml 
```

This file, contain all the addons, with their version, and configurations that we may want to enable in the cluster.

For example, If we search for **load-balancer-controller** in this file we should get this output:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='3'}

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
        annotations:
          eks.amazonaws.com/role-arn: '{{.metadata.annotations.aws_load_balancer_controller_iam_role_arn}}'
:::
<!-- prettier-ignore-end -->

We can see that this addons will be installed, if we update somehow the enable parameter which is false at the moment.

If we remember how we created the addons-applicationset, we have a way to pass several valueFiles, that can be used to change the default value depending on the context:

```bash
cat $GITOPS_DIR/platform/bootstrap/addons-applicationset.yaml | grep value
```

That should output

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

That mean we can have custom values by **environment**, **clusters**, or by **tenants**.

In this case, we are going to update the highlighted one, so, at **cluster** level.

### 4. Enable load-balancer-controller for our cluster.

In order to activate this only for our cluster, we are going to activate this at the **cluster** values file level.

let's create

```bash
mkdir -p $GITOPS_DIR/addons/clusters/hub-cluster/addons/gitops-bridge/
cp $BASE_DIR/solution/gitops/addons/clusters/hub-cluster/addons/gitops-bridge/values.yaml $GITOPS_DIR/addons/clusters/hub-cluster/addons/gitops-bridge/values.yaml
```

Commit the change

```bash
git -C ${GITOPS_DIR}/addons add .  || true
git -C ${GITOPS_DIR}/addons commit -m "Activate Load balancer controller" || true
git -C ${GITOPS_DIR}/addons push || true
```

You can refresh the application in Argo CD UI.

### 5. Apply Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply --auto-approve
```

### 6. Verify the load balancer deployment

You can accelerate the argocd reconciliation with manual sync:

```bash
argocd app sync argocd/cluster-addons
```

The Argo CD dashboard should have a load balancer application.

![hubcluster-lb-addon](/static/images/hubcluster-lb-addon.png)

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller --context hub-cluster
```
