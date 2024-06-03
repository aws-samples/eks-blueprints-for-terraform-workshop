---
title: 'Enable Karpenter'
weight: 1
---

### Step 0: Create the EC2 Spot Linked Role

We continue as Platform Team members and create the [EC2 Spot Linked role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html#service-linked-roles-spot-instance-requests), which is necessary to exist in your account in order to let you launch Spot instances.

::alert[This step is only necessary if this is the first time you’re using EC2 Spot in this account. If the role has already been successfully created, you will see: `An error occurred (InvalidInput) when calling the CreateServiceLinkedRole operation: Service role name AWSServiceRoleForEC2Spot has been taken in this account, please try a different suffix.` Just ignore the error and proceed with the rest of the workshop.]{header="Important"}

```bash
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```

### Step 1: Configure Karpenter Add-On

1. In our Terraform code in `modules/eks_cluster/main.tf` in `kubernetes_addons` add the Karpenter add-on after the  `enable_argo_rollouts` we set previously.

```bash
c9 open ~/environment/eks-blueprint/modules/eks_cluster/main.tf
```

:::code{showCopyAction=false showLineNumbers=false language=hcl}
module "kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=blueprints-workshops/modules/kubernetes-addons"

... ommitted content for brevity ...

  enable_aws_load_balancer_controller  = true
  enable_amazon_eks_aws_ebs_csi_driver = true
  enable_aws_for_fluentbit             = true
  enable_metrics_server                = true
  enable_karpenter                     = true                                       # <-- Add this line 
  karpenter_node_iam_instance_profile        = module.karpenter.instance_profile_name # <-- Add this line 
  karpenter_enable_spot_termination_handling = true                                 # <-- Add this line 
}
:::

> Save the file :)

2. Execute the following command to add the `karpenter` module in `module/eks_cluster/main.tf`. The module will create an SQS queue and Eventbridge event rule for Karpenter to utilize for spot termination handling and capacity rebalancing.

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf
################################################################################
# Karpenter
################################################################################

# Creates Karpenter native node termination handler resources and IAM instance profile
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.15.2"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  create_irsa            = false # IRSA will be created by the kubernetes-addons module

  tags = local.tags
}

EOF
```

#### Deploy Karpenter Add-On

Now run the Terraform plan to see our modifications.

```bash
cd ~/environment/eks-blueprint/eks-blue
terraform init
```

Now run the Terraform plan to see our modifications.

```bash
terraform plan
```

Now run the Terraform apply to deploy our modifications.

```bash
terraform apply --auto-approve
```

Once the deployment is done, you should see Karpenter appear in the cluster:

```bash
kubectl get pods -n karpenter
```

```
NAME                         READY   STATUS    RESTARTS   AGE
karpenter-776657675b-d8sgt   2/2     Running   0          88s
karpenter-776657675b-gj8h4   2/2     Running   0          88s
```

Congrats, You successfully installed Karpenter in your EKS cluster.
