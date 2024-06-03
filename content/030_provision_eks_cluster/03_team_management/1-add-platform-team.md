---
title: 'Add Platform Team'
weight: 1
---

As described earlier, EKS Blueprints support creating multiple teams that have different permission levels on the cluster. This is supported by the new dedicated [terraform-aws-eks-blueprints-teams](https://github.com/aws-ia/terraform-aws-eks-blueprints-teams) module.
As described earlier, EKS Blueprints support creating multiple teams that have different permission levels on the cluster. This is supported by the new dedicated [terraform-aws-eks-blueprints-teams](https://github.com/aws-ia/terraform-aws-eks-blueprints-teams) module.

Head over to the `~/environment/eks-blueprint/modules/eks_cluster/main.tf` file.

```bash
c9 open ~/environment/eks-blueprint/modules/eks_cluster/main.tf
```

## Add Platform Team

The first thing we need to do is add the Platform Team definition to our `main.tf` in the module `eks_blueprints`. This is the team that manages the EKS cluster provisioning.
The first thing we need to do is add the Platform Team definition to our `main.tf` in the module `eks_blueprints`. This is the team that manages the EKS cluster provisioning.

:::code{showCopyAction=trye showLineNumbers=true language=hcl}
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf

data "aws_iam_role" "eks_admin_role_name" {
  count     = local.eks_admin_role_name != "" ? 1 : 0
  name = local.eks_admin_role_name
}

module "eks_blueprints_platform_teams" {
  source  = "aws-ia/eks-blueprints-teams/aws"
  version = "~> 0.2"

  name = "team-platform"

  # Enables elevated, admin privileges for this team
  enable_admin = true
 
  # Define who can impersonate the team-platform Role
  users             = [
    data.aws_caller_identity.current.arn,
    try(data.aws_iam_role.eks_admin_role_name[0].arn, data.aws_caller_identity.current.arn),
  ]
  cluster_arn       = module.eks.cluster_arn
  oidc_provider_arn = module.eks.oidc_provider_arn

  labels = {
    "elbv2.k8s.aws/pod-readiness-gate-inject" = "enabled",
    "appName"                                 = "platform-team-app",
    "projectName"                             = "project-platform",
  }

  annotations = {
    team = "platform"
  }

  namespaces = {
    "team-platform" = {

      resource_quota = {
        hard = {
          "requests.cpu"    = "10000m",
          "requests.memory" = "20Gi",
          "limits.cpu"      = "20000m",
          "limits.memory"   = "50Gi",
          "pods"            = "20",
          "secrets"         = "20",
          "services"        = "20"
        }
      }

      limit_range = {
        limit = [
          {
            type = "Pod"
            max = {
              cpu    = "1000m"
              memory = "1Gi"
            },
            min = {
              cpu    = "10m"
              memory = "4Mi"
            }
          },
          {
            type = "PersistentVolumeClaim"
            min = {
              storage = "24M"
            }
          }
        ]
      }
    }

  }

  tags = local.tags
}
EOF
:::

::alert[The label **elbv2.k8s.aws/pod-readiness-gate-inject** injected here is used by the AWS Load Balancer Controller to only mark pods **ready** at Kubernetes levels when they are correctly registered in the associated load balancer. To learn more, see [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/networking/loadbalancing/loadbalancing/)]{header="Important"}

Before applying this change, let's go over the code you've just added. First, we instanciate a new module `eks_blueprints_platform_teams` from the eks blueprint teams module.
Our `team-platform` will be Admin of the EKS cluster, so we activate this option on line 15.
The module will create a new IAM Role and we define on line 18 which other entities (user or roles) will be able to impersonate this role and be able to gain Admin access on the cluster. For this we reuse the local configure from our module variable to specify the additional IAM Role.

We also want our platform-team to own a dedicated Kubernetes namespace so that they can deploy some cluster level Kubernetes objects, like Network policies, Security control manifest, Autoscaling configuration...
Line 35 we create the team-platform namespace, and because this is a shared EKS cluster, we create **resources_quota (line38)** for this namespace, and a **limit_range (line 50)** object.

::alert[Don't forget to save the cloud9 file as auto-save is not enabled by default.]{header="Important"}

Now using the Terraform CLI, update the resources in AWS using the cli, note the `-auto-approve` flag that skips user approval to deploy changes without having to type “yes” as a confirmation to provision resources.

```bash
# We need to do this again since we added a new module.
# We need to do this again since we added a new module.
cd ~/environment/eks-blueprint/eks-blue
terraform init
```

View the Terraform plan:
View the Terraform plan:

```bash
# It is always a good practice to use a dry-run command
# It is always a good practice to use a dry-run command
terraform plan
```

Now using the Terraform CLI, update the resources in AWS using the cli. Note the `-auto-approve` flag that skips user approval to deploy changes without having to type “yes” as a confirmation to provision resources.
Now using the Terraform CLI, update the resources in AWS using the cli. Note the `-auto-approve` flag that skips user approval to deploy changes without having to type “yes” as a confirmation to provision resources.

```bash
# then provision our EKS cluster
# the auto approve flag avoids you having to confirm you want to provision resources.
terraform apply -auto-approve
```

This will create a dedicated role similar to `arn:aws:iam::0123456789:role/team-platform-XXXXXXXXXXXX` that will allow you to manage the cluster as an administrator.
This will create a dedicated role similar to `arn:aws:iam::0123456789:role/team-platform-XXXXXXXXXXXX` that will allow you to manage the cluster as an administrator.

It also defines which existing users/roles will be allowed to assume this role via the `users` parameter, where you can provide a list of IAM arns.
It also defines which existing users/roles will be allowed to assume this role via the `users` parameter, where you can provide a list of IAM arns.
The new role is also configured in the EKS àws-auth` Configmap to allow authentication into the EKS Kubernetes cluster.

When Terraform finishes its run, you can explore the new objects it created.

We can see, for instance, that a new namespace has been created:
We can see, for instance, that a new namespace has been created:

```bash
kubectl get ns
```

The output should look as below (ignore the AGE column). As you can see, a new namespace called `team-platform` was created.
The output should look as below (ignore the AGE column). As you can see, a new namespace called `team-platform` was created.

```
NAME              STATUS   AGE
default           Active   19h
kube-node-lease   Active   19h
kube-public       Active   19h
kube-system       Active   19h
team-platform     Active   43m
```

Next, if we run:
Next, if we run:

```bash
kubectl describe resourcequotas -n team-platform
```

We can see the resource quotas allowed for this new namespace, and if we run:

```bash
kubectl describe limitrange -n team-platform
```

We will see the limit-range configuration that has been applied, allowing us to add default resources/limits quotas to our applications.
We will see the limit-range configuration that has been applied, allowing us to add default resources/limits quotas to our applications.


There are several other resources created when you onboard a team, including a **Kubernetes Service Account** created for the team. This service account can also be used by our applications deployed into this namespace to inherit the IAM permissions associated with the IAM Role associated; you can see it with the special annotation **eks.amazonaws.com/role-arn**
There are several other resources created when you onboard a team, including a **Kubernetes Service Account** created for the team. This service account can also be used by our applications deployed into this namespace to inherit the IAM permissions associated with the IAM Role associated; you can see it with the special annotation **eks.amazonaws.com/role-arn**

```bash
kubectl describe sa -n team-platform team-platform
```

We can also explore the Terraform state files generated by our apply using `terraform state list` and you should see resources similar to the ones shown below:
We can also explore the Terraform state files generated by our apply using `terraform state list` and you should see resources similar to the ones shown below:

```bash
terraform state list module.eks_cluster.module.eks_blueprints_platform_teams
```

:::code{showCopyAction=false language=hcl}
module.eks_cluster.module.eks_blueprints_platform_teams.data.aws_iam_policy_document.admin[0]
module.eks_cluster.module.eks_blueprints_platform_teams.data.aws_iam_policy_document.this[0]
module.eks_cluster.module.eks_blueprints_platform_teams.aws_iam_policy.admin[0]
module.eks_cluster.module.eks_blueprints_platform_teams.aws_iam_role.this[0]
module.eks_cluster.module.eks_blueprints_platform_teams.aws_iam_role_policy_attachment.admin[0]
module.eks_cluster.module.eks_blueprints_platform_teams.kubernetes_limit_range_v1.this["team-platform"]
module.eks_cluster.module.eks_blueprints_platform_teams.kubernetes_namespace_v1.this["team-platform"]
module.eks_cluster.module.eks_blueprints_platform_teams.kubernetes_resource_quota_v1.this["team-platform"]
module.eks_cluster.module.eks_blueprints_platform_teams.kubernetes_service_account_v1.this["team-platform"]
:::

You can see in more detail in the `terraform state` what AWS resources were created with our team module.
For example, you can see the platform team details:
You can see in more detail in the `terraform state` what AWS resources were created with our team module.
For example, you can see the platform team details:

```bash
terraform state show 'module.eks_cluster.module.eks_blueprints_platform_teams.aws_iam_role.this[0]'
```

:::code{showCopyAction=false language=hcl}
# module.eks_cluster.module.eks_blueprints_platform_teams.aws_iam_role.this[0]:
resource "aws_iam_role" "this" {
    arn                   = "arn:aws:iam::518175083565:role/team-platform-20230606102245638700000002"
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                        AWS = "arn:aws:sts::518175083565:assumed-role/eks-blueprints-for-terraform-workshop-admin/i-0da6fe84e15a05ae3"
                    }
                    Sid       = "AssumeRole"
                },
            ]
            Version   = "2012-10-17"
        }
    )
    create_date           = "2023-06-06T10:22:45Z"
    force_detach_policies = true
    id                    = "team-platform-20230606102245638700000002"
    managed_policy_arns   = []
    max_session_duration  = 3600
    name                  = "team-platform-20230606102245638700000002"
    name_prefix           = "team-platform-"
    path                  = "/"
    tags                  = {
        "Blueprint"  = "eks-blueprint-blue"
        "GithubRepo" = "github.com/aws-ia/terraform-aws-eks-blueprints"
    }
    tags_all              = {
        "Blueprint"  = "eks-blueprint-blue"
        "GithubRepo" = "github.com/aws-ia/terraform-aws-eks-blueprints"
    }
    unique_id             = "AROAXRJNEJQWWVIG7RPDM"
}
:::

Let's see how we can leverage the roles associated with our newly created Teams, in the next section.
Let's see how we can leverage the roles associated with our newly created Teams, in the next section.
