---
title: 'Configure Workload for Karpenter'
weight: 3
---

### Step 4: Configure Karpenter from Terraform

#### Configure `karpenterInstanceProfile` from Terraform

First, in the `modules/eks_cluser/locals.tf` in the `workload_application.values.spec` uncomment the `karpenterInstanceProfile` so that our workloads know that we can use Karpenter. We have configured our `deployment.yaml` to add Karpenter nodeSelector and toleration if this parameter exists, and our karpenter provisioner to only be deployed when this value exists.


Uncomment the line by executing the following command or doing it manually:

```bash
sed -i "s/^\(\s*\)#\(karpenterInstanceProfile.*\)/\1\2/" ~/environment/eks-blueprint/modules/eks_cluster/locals.tf
grep workload_application -A 25  ~/environment/eks-blueprint/modules/eks_cluster/locals.tf
```

The outputs should look like:

```
  workload_application = {
    path                = local.workload_repo_path # <-- we could also to blue/green on the workload repo path like: envs/dev-blue / envs/dev-green
    repo_url            = local.workload_repo_url
    target_revision     = local.workload_repo_revision

    add_on_application  = false
    
    values = {
      labels = {
        env   = local.env
      }
      spec = {
        source = {
          repoURL        = local.workload_repo_url
          targetRevision = local.workload_repo_revision
        }
        blueprint                = "terraform"
        clusterName              = local.name
        karpenterInstanceProfile = module.karpenter.instance_profile_name <-- This line must be uncommented
        env                      = local.env
      }
    }
  }  

}
```

#### Authorize Karpenter nodes to connect to the EKS cluster

When Karpenter creates EC2 instances, they need to be allowed to connect and register with the EKS cluster. For that, we need to allow the IAM role of the Karpenter nodes to connect to the cluster. This is done by updating the terraform section that configures the EKS `aws-auth` configMap.

In Cloud9, open the eks_cluster main file: 

```bash
c9 open ~/environment/eks-blueprint/modules/eks_cluster/main.tf
```

Uncomment the lines so that the file looks like

```hcl
...
  aws_auth_roles = flatten([
    module.eks_blueprints_platform_teams.aws_auth_configmap_role,
    [for team in module.eks_blueprints_dev_teams : team.aws_auth_configmap_role],
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.eks_admin_role_name}" # The ARN of the IAM role
      username = "ops-role"                                                                                      # The user name within Kubernetes to map to the IAM role
      groups   = ["system:masters"]                                                                              # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
    }
  ])
...
```

> Be careful with the indentation, and don't forget to save the file (auto-save is not enabled by default in Cloud9)

#### Apply the change
```bash
cd ~/environment/eks-blueprint/eks-blue
terraform apply --auto-approve
```

Check the Karpenter provisioner

Once ArgoCD has synchronized or changed the new parameter, we can check that the provisioner has been created. Wait a little if you don't see the provisioners yet.

Get the default provisioner:

```bash
kubectl get provisioner
```

```
NAME      AGE
default   8m33s
```
