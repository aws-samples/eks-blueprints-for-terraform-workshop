---
title: 'Clean up'
weight: 90
---



### Step 1: Delete an eks-blue or eks-green stack.

To cleanup your cluster stack, simply run the following commands in this specific order:


::alert[Removing resources in this specific order ensures dependencies are deleted entirely.  VPCs, subnets, and IP addresses attached to ENIs are all deleted last.]{header="Important"}



#### Step 1.1: Delete the workloads

We have deployed all our workloads using ArgoCD. But we also used ArgoCD to deploy all our AWS controllers (like the AWS load blancer controller and Karpenter).


Those controllers, in response to some workload events, were able to create additional AWS resources that were not known by Terraform.
In order to let Terraform cleanup all resources it has created, we first need to delete resources created outside of Terraform like load balancers, Karpenter nodes, EBS volumes, etc.

For that, we will update our Terraform ArgoCD configuration and comment on or delete the lines deploying the workloads, but it is very important to keep the line that has deployed those add-ons. So when the workload resources are deleted, the add-ons can free up the additional AWS resources they created.

Update our `main.tf` with the removal of workloads except addons.






 ~/environment/wgit/assets/scripts/destroy.sh staging




```bash
  argocd_applications = {
    addons    = local.addon_application # YOU NEED TO KEEP ADDONS
    #workloads = local.workload_application # Comment to remove workloads
  }
```

Then run again, apply to make this take into account

```bash
terraform apply -auto-approve
```

### Remove first Kubernetes AddOns module

```hcl
terraform destroy -target=module.eks_cluster.module.kubernetes_addon -auto-approve
```

::::expand{header="View Terraform Output"}

```
.....

module.kubernetes-addons.module.argocd[0].helm_release.argocd_application["addons"]: Destroying... [id=addons]
module.kubernetes-addons.module.argocd[0].helm_release.argocd_application["workloads"]: Destroying... [id=workloads]
module.kubernetes-addons.module.argocd[0].helm_release.argocd_application["addons"]: Destruction complete after 4s
module.kubernetes-addons.module.argocd[0].helm_release.argocd_application["workloads"]: Still destroying... [id=workloads, 10s elapsed]
module.kubernetes-addons.module.argocd[0].helm_release.argocd_application["workloads"]: Still destroying... [id=workloads, 20s elapsed]
module.kubernetes-addons.module.argocd[0].helm_release.argocd_application["workloads"]: Destruction complete after 30s
module.kubernetes-addons.module.argocd[0].module.helm_addon.helm_release.addon[0]: Destroying... [id=argo-cd]
module.kubernetes-addons.module.argocd[0].module.helm_addon.helm_release.addon[0]: Destruction complete after 7s
module.kubernetes-addons.module.argocd[0].kubernetes_namespace_v1.this: Destroying... [id=argocd]
module.kubernetes-addons.module.argocd[0].kubernetes_namespace_v1.this: Still destroying... [id=argocd, 10s elapsed]
module.kubernetes-addons.module.argocd[0].kubernetes_namespace_v1.this: Still destroying... [id=argocd, 20s elapsed]
module.kubernetes-addons.module.argocd[0].kubernetes_namespace_v1.this: Destruction complete after 24s

Apply complete! Resources: 0 added, 0 changed, 4 destroyed.

Outputs:

configure_kubectl = "aws eks --region us-west-1 update-kubeconfig --name tst-stg-mkt-eks"
private_subnets = [
  "subnet-0811ed9f8ccfdb46d",
  "subnet-0ef83197e29697391",
]
public_subnets = [
  "subnet-0bc9fbb37b55e34e4",
  "subnet-0aec53a1833281de4",
]
vpc_id = "vpc-0b7bbf428b0a4dda6"
```

::::



Next, delete the `eks_blueprints` module from `main.tf` file.

### We can now safely delete our EKS Cluster

```hcl
terraform destroy -target=module.eks_cluster.module.eks_blueprints -auto-approve
```

::::expand{header="View Terraform Output"}

```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

module.eks_blueprints.module.kms[0].aws_kms_alias.this: Destroying... [id=alias/tst-stg-mkt-eks]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role_policy_attachment.managed_ng_AmazonSSMManagedInstanceCore: Destroying... [id=tst-stg-mkt-eks-managed-ondemand-20220523220619215300000006]
module.eks_blueprints.module.aws_eks.aws_iam_openid_connect_provider.oidc_provider[0]: Destroying... [id=arn:aws:iam::540060600283:oidc-provider/oidc.eks.us-west-1.amazonaws.com/id/E9796B2C80FBB8A26CAA7240F463A009]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009]
module.eks_blueprints.module.kms[0].aws_kms_alias.this: Destruction complete after 1s
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role_policy_attachment.managed_ng_AmazonSSMManagedInstanceCore: Destruction complete after 2s
module.eks_blueprints.module.aws_eks.aws_iam_openid_connect_provider.oidc_provider[0]: Destruction complete after 2s
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 10s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 20s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 30s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 40s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 50s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 1m0s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 1m10s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 1m20s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 1m30s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 1m40s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 1m50s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 2m0s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 2m10s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 2m20s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 2m30s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 2m40s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 2m50s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 3m0s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Still destroying... [id=tst-stg-mkt-eks:managed-ondemand-20220523220620262700000009, 3m10s elapsed]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_eks_node_group.managed_ng: Destruction complete after 3m19s
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role_policy_attachment.managed_ng_AmazonEKSWorkerNodePolicy: Destroying... [id=tst-stg-mkt-eks-managed-ondemand-20220523220619416400000008]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role_policy_attachment.managed_ng_AmazonEKS_CNI_Policy: Destroying... [id=tst-stg-mkt-eks-managed-ondemand-20220523220619068500000005]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role_policy_attachment.managed_ng_AmazonEC2ContainerRegistryReadOnly: Destroying... [id=tst-stg-mkt-eks-managed-ondemand-20220523220619317300000007]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_instance_profile.managed_ng: Destroying... [id=tst-stg-mkt-eks-managed-ondemand]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role_policy_attachment.managed_ng_AmazonEC2ContainerRegistryReadOnly: Destruction complete after 2s
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role_policy_attachment.managed_ng_AmazonEKSWorkerNodePolicy: Destruction complete after 2s
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role_policy_attachment.managed_ng_AmazonEKS_CNI_Policy: Destruction complete after 2s
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_instance_profile.managed_ng: Destruction complete after 2s
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role.managed_ng: Destroying... [id=tst-stg-mkt-eks-managed-ondemand]
module.eks_blueprints.module.aws_eks_managed_node_groups["mg_4"].aws_iam_role.managed_ng: Destruction complete after 1s
module.eks_blueprints.kubernetes_config_map.aws_auth[0]: Destroying... [id=kube-system/aws-auth]
module.eks_blueprints.kubernetes_config_map.aws_auth[0]: Destruction complete after 1s
module.eks_blueprints.module.aws_eks.aws_eks_cluster.this[0]: Destroying... [id=tst-stg-mkt-eks]
module.eks_blueprints.module.aws_eks.aws_eks_cluster.this[0]: Still destroying... [id=tst-stg-mkt-eks, 10s elapsed]
module.eks_blueprints.module.aws_eks.aws_eks_cluster.this[0]: Still destroying... [id=tst-stg-mkt-eks, 20s elapsed]
module.eks_blueprints.module.aws_eks.aws_eks_cluster.this[0]: Still destroying... [id=tst-stg-mkt-eks, 30s elapsed]
module.eks_blueprints.module.aws_eks.aws_eks_cluster.this[0]: Still destroying... [id=tst-stg-mkt-eks, 40s elapsed]
module.eks_blueprints.module.aws_eks.aws_eks_cluster.this[0]: Still destroying... [id=tst-stg-mkt-eks, 50s elapsed]
module.eks_blueprints.module.aws_eks.aws_eks_cluster.this[0]: Still destroying... [id=tst-stg-mkt-eks, 1m0s elapsed]
module.eks_blueprints.module.aws_eks.aws_eks_cluster.this[0]: Destruction complete after 1m9s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.cluster["egress_nodes_443"]: Destroying... [id=sgrule-2961694048]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]: Destroying... [id=sgrule-3113263846]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.cluster["egress_nodes_kubelet"]: Destroying... [id=sgrule-4038023841]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["ingress_self_coredns_udp"]: Destroying... [id=sgrule-500105481]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_self_coredns_udp"]: Destroying... [id=sgrule-3935588340]
module.eks_blueprints.module.aws_eks.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"]: Destroying... [id=tst-stg-mkt-eks-cluster-role-20220523215722935900000004]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_https"]: Destroying... [id=sgrule-2166386433]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["ingress_cluster_443"]: Destroying... [id=sgrule-1455549782]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.cluster["ingress_nodes_443"]: Destroying... [id=sgrule-3942073798]
module.eks_blueprints.module.aws_eks.aws_cloudwatch_log_group.this[0]: Destroying... [id=/aws/eks/tst-stg-mkt-eks/cluster]
module.eks_blueprints.module.aws_eks.aws_cloudwatch_log_group.this[0]: Destruction complete after 1s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_cluster_443"]: Destroying... [id=sgrule-1415930718]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.cluster["egress_nodes_443"]: Destruction complete after 1s
module.eks_blueprints.module.aws_eks.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"]: Destruction complete after 1s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["ingress_cluster_kubelet"]: Destroying... [id=sgrule-884976365]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_ntp_udp"]: Destroying... [id=sgrule-543192850]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_https"]: Destruction complete after 2s
module.eks_blueprints.module.kms[0].aws_kms_key.this: Destroying... [id=f569d23f-de26-467d-9633-3a9a3ccfa01a]
module.eks_blueprints.module.kms[0].aws_kms_key.this: Destruction complete after 0s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_self_coredns_tcp"]: Destroying... [id=sgrule-1693699474]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.cluster["egress_nodes_kubelet"]: Destruction complete after 2s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_ntp_tcp"]: Destroying... [id=sgrule-1593725471]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["ingress_cluster_443"]: Destruction complete after 2s
module.eks_blueprints.module.aws_eks.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]: Destroying... [id=tst-stg-mkt-eks-cluster-role-20220523215722804800000003]
module.eks_blueprints.module.aws_eks.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]: Destruction complete after 0s
module.eks_blueprints.module.aws_eks.aws_iam_role.this[0]: Destroying... [id=tst-stg-mkt-eks-cluster-role]
module.eks_blueprints.module.aws_eks.aws_security_group_rule.cluster["ingress_nodes_443"]: Destruction complete after 2s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_self_coredns_udp"]: Destruction complete after 2s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["ingress_self_coredns_udp"]: Destruction complete after 3s
module.eks_blueprints.module.aws_eks.aws_iam_role.this[0]: Destruction complete after 1s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]: Destruction complete after 3s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_cluster_443"]: Destruction complete after 3s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["ingress_cluster_kubelet"]: Destruction complete after 2s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_ntp_udp"]: Destruction complete after 2s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_self_coredns_tcp"]: Destruction complete after 3s
module.eks_blueprints.module.aws_eks.aws_security_group_rule.node["egress_ntp_tcp"]: Destruction complete after 3s
module.eks_blueprints.module.aws_eks.aws_security_group.cluster[0]: Destroying... [id=sg-0f61f9a924c49e262]
module.eks_blueprints.module.aws_eks.aws_security_group.node[0]: Destroying... [id=sg-0d0debff93d4f76df]
module.eks_blueprints.module.aws_eks.aws_security_group.cluster[0]: Destruction complete after 1s
module.eks_blueprints.module.aws_eks.aws_security_group.node[0]: Destruction complete after 1s
╷
│ Warning: Applied changes may be incomplete
│
│ The plan was created with the -target option in effect, so some changes requested in the configuration
│ may have been ignored and the output values may not be fully updated. Run the following command to
│ verify that no other changes are pending:
│     terraform plan
│
│ Note that the -target option is not suitable for routine use, and is provided only for exceptional
│ situations such as recovering from errors or mistakes, or when Terraform specifically suggests to use
│ it as part of an error message.
╵

Destroy complete! Resources: 31 destroyed.
```

::::

Next, delete the remaining modules from the `main.tf`

#### Step 1.4: Finally, we can delete the whole stack
#### Step 1.4: Finally, we can delete the whole stack

```hcl
terraform destroy -auto-approve
```



### Step 2: Delete an eks-blue or eks-green stack.

Repeat Step 1 but for the other cluster


### Step 3: Delete the environment terraform stack

```bash
cd ~/environment/eks-blueprint/environment
```

```hcl
terraform destroy -auto-approve
```

> Congratulations! You should have removed everything installed by the workshop.
> Congratulations! You should have removed everything installed by the workshop.