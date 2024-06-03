---
title: 'Architecture with existing Load Balancer'
weight: 1
---

## Create an External Application Load Balancer

We are going to update our architecture to be able to address this goal.
In this scenario, we rely on an existing Application Load Balancer, that we manually declare in our common **environment** stack using Terraform. The ALB is associated with 2 target groups, one for the blue cluster and the other for the green cluster. With this architecture we are able to migrate from one cluster to the other using the ALB directly by relying on [Weighted TargetGroup](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html) on the ALB Listener.

The ALB listener controls the percentage of requests we want to send to either blue or green target groups by changing the associated weights in the Listener.

### 1. Create the ALB and listeners

Use this command to add the ALB creation in the environment terraform stack:

```bash
cat >> ~/environment/eks-blueprint/environment/main.tf <<'EOF'

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.3"

  name               = "${local.name}-alb"
  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  #security_groups = [module.vpc.default_security_group_id]
  security_group_rules = {
    ingress_all_http = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      #cidr_blocks = [for s in module.vpc.private_subnets_cidr_blocks : s.cidr_block]
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  http_tcp_listeners = [
    {
      port                = "80"
      protocol            = "HTTP"
      action_type         = "forward"
    },
  ]

  target_groups = [
    {
      name                    = "${local.name}-tg-blue"
      backend_protocol        = "HTTP"
      backend_port            = "80"
      target_type             = "ip"
      deregistration_delay    = 10      
      health_check = {
        path    = "/healthz"
        port    = "80"
        matcher = "200-299"
      }
    },
    {
      name                    = "${local.name}-tg-green"
      backend_protocol        = "HTTP"
      backend_port            = "80"
      target_type             = "ip"
      deregistration_delay    = 10      
      health_check = {
        path    = "/healthz"
        port    = "80"
        matcher = "200-299"
      }
    },    
  ]

  http_tcp_listener_rules = [
    {
      actions = [{
        type = "weighted-forward"
        target_groups = [
          {
            target_group_index = 0
            weight             = 100
          },
          {
            target_group_index = 1
            weight             = 0
          }
        ]
        stickiness = {
          enabled  = true
          duration = 3600
        }
      }]

      conditions = [{
        path_patterns = ["/*"]
      }]
    }
  ]

  tags = local.tags
}


EOF
```

Also, add this to the outputs.tf file to expose the newly created resource:

```bash
cat >> ~/environment/eks-blueprint/environment/outputs.tf <<'EOF'

output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.alb.lb_dns_name
}

output "lb_arn" {
  description = "The ID and ARN of the load balancer we created."
  value       = module.alb.lb_arn
}

output "lb_security_group" {
  description = "The security group of the load balancer."
  value       = module.alb.security_group_id
}

output "target_group_arns" {
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group."
  value       = module.alb.target_group_arns
}

EOF
```

Then we can update the environment stack:

```bash
# Initialize Terraform so that we get all the required modules and providers
cd ~/environment/eks-blueprint/environment
tfi && tfy
```

::alert[`tfi` and `tfy` are aliases that have been created for your environmen. You can find them all by just typing `alias`]{header="Important"}.

You can see the new ALB created by following this [deep link](https://console.aws.amazon.com/ec2/home?#LoadBalancers:v=3;tag:Name=eks-blueprint-alb).

### 2. Pass the TargetGroup Arn from Terraform to ArgoCD

When deploying our applications in our cluster, we need to deploy resources using the associated TargetGroup that we just created in the environment stack (either blue or green, depending on the cluster name).

We enrich the ArgoCD application values we already use to provide some data from Terraform to ArgoCD.

This is declared by the locals.tf file:

```bash  
c9 open ~/environment/eks-blueprint/modules/eks_cluster/locals.tf
```

Update the **workload_application** section and add the **target_group_arn** parameter so that it looks like:

```
  #---------------------------------------------------------------
  # ARGOCD WORKLOAD APPLICATION
  #---------------------------------------------------------------

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
        karpenterInstanceProfile = module.karpenter.instance_profile_name 
        env                      = local.env
        #< Add the following line>
        target_group_arn         = local.service == "blue" ? data.aws_lb_target_group.tg_blue.arn : data.aws_lb_target_group.tg_green.arn # <-- Add this line
      }
    }
  }  

}
```

> If we deploy in the blue cluster, we add the blue target group, and if we deploy in the green cluster, we add the green target Group.

Now declare the 2 data sources: 

```bash
cat >> ~/environment/eks-blueprint/modules/eks_cluster/locals.tf << 'EOF'

data "aws_lb_target_group" "tg_blue" {
  name = "${local.environment}-tg-blue"
}

data "aws_lb_target_group" "tg_green" {
  name = "${local.environment}-tg-green"
}

data "aws_lb" "alb" {
  name = "${local.environment}-alb"
}

data "aws_security_group" "alb_sg" {
  count = 1
  id    = tolist(data.aws_lb.alb.security_groups)[count.index]
}

EOF
```
