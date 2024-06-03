---
title: 'Expose our application'
weight: 2
---

With this architecture pattern, we rely on an existing target group to expose our applications. If we have 20 applications, we may need to declare 20 target groups in the **environment** stack and sync them with our EKS services.

To simplify the process of exposing our applications to the existing target groups, we have adopted a different approach using an **in-cluster** ingress controller, exposed to the existing targetgroup corresponding to the color of the cluster (blue or green).

Fortunately, the EKS Blueprints already includes the [Nginx Ingress Controller Add-On](https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.32.1/add-ons/nginx/), which we will utilize.

The final **in-cluster** routing will be done by creating Ingress objects using the nginx IngressClass. This configuration enables nginx to function as a reverse-proxy, forwarding requests to the designated service, in this case, our skiapp application.

By adopting this approach, each cluster will operate independently, and the ALB will determine which cluster to use based on the target group weights. This method not only reduces complexity but also provides greater control over routing requests within our infrastructure.

![](/static/images/blue-green-targetgroup.png)

## 1. Install Nginx ingress

1. In our Terraform code in `modules/eks_cluster/main.tf` in `kubernetes_addons` add the Karpenter add-on after the  `enable_argo_rollouts` we set previously.

```bash
c9 open ~/environment/eks-blueprint/modules/eks_cluster/main.tf
```

:::code{showCopyAction=false showLineNumbers=false language=hcl}
module "kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.0/modules/kubernetes-addons"

... omitted content for brevity ...

  enable_aws_load_balancer_controller  = true
  enable_amazon_eks_aws_ebs_csi_driver = true
  enable_aws_for_fluentbit             = true
  enable_metrics_server                = true
  enable_karpenter                     = true
  karpenter_node_iam_instance_profile        = module.karpenter.instance_profile_name  
  karpenter_enable_spot_termination_handling = true
  enable_kubecost                      = true
  enable_ingress_nginx                 = true                                       # <-- Add this line
}
:::

In the same file, add the following section to allow the ALB to communicate with Karpenter and Fargate nodes:

```
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15.2"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.private.ids

  # We use only 1 security group to allow connections with Fargate, MNG, and Karpenter nodes.
  create_node_security_group = false

  # Extend cluster security group rules with the external ALB  # <-- Add this block
  cluster_security_group_additional_rules = {   
    ingress_alb_security_group_id = {
      description              = "Ingress from environment ALB security group"
      protocol                 = "tcp"
      from_port                = 80
      to_port                  = 80
      type                     = "ingress"
      source_security_group_id = data.aws_security_group.alb_sg[0].id
    }
  }

...
```  

<!--
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }   
    ingress_alb_security_group_id = {
      description              = "Ingress from environment ALB security group"
      protocol                 = "tcp"
      from_port                = 80
      to_port                  = 80
      type                     = "ingress"
      #source_security_group_id = data.aws_lb.alb.security_groups[length(data.aws_lb.alb.security_groups)]
      source_security_group_id = data.aws_security_group.alb_sg[0].id
    }
  }  
  -->


Also execute this to enable communication from ALB to managed node groupes:

```bash
cat << 'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf

resource "aws_security_group_rule" "alb" {
  security_group_id = module.eks.cluster_primary_security_group_id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  description       = "Ingress from environment ALB security group"
  source_security_group_id = data.aws_security_group.alb_sg[0].id
}

EOF
```


Now run the Terraform plan to see our modifications:

```bash
cd ~/environment/eks-blueprint/eks-blue
terraform apply --auto-approve
```

After syncing your ArgoCD **workload** application, you should be able to see the target_group_arns parameter with the value of the blue target group arn:

![](/static/images/argocd_values_targetgroup.png)


::alert[By default, the ingress-nginx addons are exposed through a NLB. This is controlled by the [addon values](https://github.com/aws-samples/eks-blueprints-add-ons/blob/main/add-ons/ingress-nginx/values.yaml). This NLB can be used to validate the good working of your application directly with the NLB URL. You can remove the annotations to deactivate this feature]{header="NLB Preview"}.


## 2. Register Nginx service in the TargetGroup

We have started the setup of our architecture:

1. We created blue and green target groups in our environment stack.
2. We installed nginx ingress in the EKS cluster.
3. We provide the target group arn in the values of our ArgoCD workload_application.

What we need to do now is link the nginx pods to the associated target group.
To accomplish this, we utilize [TargetGroupBinding](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.5/guide/targetgroupbinding/targetgroupbinding/), which is a custom resource managed by the AWS Load Balancer Controller that will register every pod ip of our nginx ingress to the load balancer target group.

One significant advantage is that the load balancer remains static throughout the creation and deletion of Ingresses or even clusters. The load balancer's lifecycle becomes independent of the service it exposes, simplifying future application migrations between our blue and green clusters.

By taking this approach, we gain better control over load balancer management, ensuring its stability and easing the process of transitioning our applications between blue and green clusters in the future.

### Go to your workload repository in codespace


```bash
cat << EOF > teams/team-riker/dev/templates/alb-skiapp/nginx-target-group-binding.md
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: nginx-ingress-tgb
  namespace: ingress-nginx
spec:
  serviceRef: 
    name: ingress-nginx-controller
    port: 80
  targetGroupARN: "{{ .Values.spec.target_group_arn }}"
EOF
```

Add the content to the repository:

```bash
git add .
git commit -m "add Nginx targetgroupbinding"
git push
```

Check the creation of the target group binding in ArgoCD:

![](/static/images/nginx-ingress-tgb.png)

## 3. Create the Nginx ingress to route on the application

Still in the codespace repository, create the nginx ingress:

```bash
cat << EOF > teams/team-riker/dev/templates/alb-skiapp/skiapp-ingress-nginx.md
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: skiapp-ingress-nginx
  namespace: team-riker
spec:
  ingressClassName: nginx
  rules:
    - host: 
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: skiapp-service
                port:
                  number: 80
EOF
```

Validate the new content:

```bash
git add .
git commit -m "add Ingress for our Skiapp with Nginx"
git push
```

As previously explained, you can see a preview of your application in each cluster by clicking on the Ingress link:
![](/static/images/skiapp-ingress-nginx.png)

## 4. Accessing the application from your external ALB

The whole purpose of our blue/green migration is to be able to access the application through our external Application Load Balancer managed by our **environment** Terraform stack.

You can access the skiapp application from the ALB

```bash
export ALB_DNS=`aws elbv2 describe-load-balancers --names eks-blueprint-alb --query 'LoadBalancers[0].DNSName' --output text`
echo export ALB_DNS=\"$ALB_DNS\" >> ~/.bashrc
echo "http://$ALB_DNS"
```

Access the application from the LB:

```bash
curl $ALB_DNS
```



