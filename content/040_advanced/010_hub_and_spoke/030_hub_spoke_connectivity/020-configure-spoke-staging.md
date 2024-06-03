---
title: 'Configure Spoke Staging'
weight: 20
---

In the previous chapter, an IAM role was created for the Hub Cluster's ArgoCD. In this chapter, another IAM role (spoke) will be created that can be assumed by the Hub Cluster's IAM role.

![Hub Role](/static/images/hub-spoke-spoke-role.png)

### 1. Create ArgoCD spoke-staging cluster with  hub-cluster

The Hub Cluster manages all cluster objects created in the Hub's ArgoCD. The spoke-staging cluster should also be managed by the Hub's ArgoCD. Use GitOps Bridge to create the spoke-staging cluster object in the hub cluster. The spoke Terraform can update the Hub because the provider setting `'kubernetes = kubernetes.hub'` allows access. 

The spoke cluster does not need its own ArgoCD installation since it depends on the Hub's ArgoCD. You can prevent ArgoCD installation on the spoke by setting the GitOps bridge configuration `'install = false'`.

```bash
cat <<'EOF' >> ~/environment/spoke/main.tf

################################################################################
# Kubernetes Access for Hub Cluster
################################################################################
provider "kubernetes" {
  host                   = data.terraform_remote_state.hub.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.hub.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.hub.outputs.cluster_name, "--region", data.terraform_remote_state.hub.outputs.cluster_region]
  }
  alias = "hub"
}
################################################################################
# GitOps Bridge: Bootstrap for Hub Cluster
################################################################################
module "gitops_bridge_bootstrap_hub" {
  source  = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"

  # The ArgoCD remote cluster secret is deploy on hub cluster not on spoke clusters
  providers = {
    kubernetes = kubernetes.hub
  }

  install = false # We are not installing argocd via helm on hub cluster
  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = local.environment
    metadata     = local.addons_metadata
    addons       = local.addons
    server       = module.eks.cluster_endpoint
    config       = <<-EOT
      {
        "tlsClientConfig": {
          "insecure": false,
          "caData" : "${module.eks.cluster_certificate_authority_data}"
        },
        "awsAuthConfig" : {
          "clusterName": "${module.eks.cluster_name}",
          "roleARN": "${aws_iam_role.spoke.arn}"
        }
      }
    EOT
  }
}

EOF
```

### 2. Spoke Role to trust Hub Role

Create an IAM role for the spoke cluster that can be assumed by the Hub's ArgoCD.

```bash
cat <<'EOF' >> ~/environment/spoke/main.tf
################################################################################
# ArgoCD EKS Access
################################################################################
resource "aws_iam_role" "spoke" {
  name               = "${local.name}-argocd-spoke"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole","sts:TagSession"]
    principals {
      type        = "AWS"
      identifiers = [data.terraform_remote_state.hub.outputs.argocd_iam_role_arn]
    }
  }
}

EOF
```
### 3. Spoke Role to assume admin access on the spoke cluster

The spoke IAM role should have admin access on the spoke Kubernetes cluster. This spoke IAM role will be assumed by the Hub ArgoCD. It needs admin access in order to create addons, namespaces, and deploy workloads on the spoke cluster.

```bash
sed -i "s/#enablespokearn //g" ~/environment/spoke/main.tf
```
The code snippet above uncomments code to grant admin access to the spoke IAM role. The changes made are highlighted as follows:

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='4-15'}
  access_entries = {
    .
    .
    gitops_role = {
      principal_arn     = aws_iam_role.spoke.arn
      policy_associations = {
        argocd = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }    
  } 

:::

### 4. Allow Hub Nodes to access to Spoke cluster
In this workshop, the hub and spoke clusters are on the same VPC. The Hub ArgoCD issues commands to the spoke Kubernetes cluster to create namespaces, deploy addons, etc. The spoke cluster's security group should allow inbound traffic on port 443 from the Hub node's security group.

```bash
cat <<'EOF' >> ~/environment/spoke/main.tf

resource "aws_vpc_security_group_ingress_rule" "hub_to_spoke" {
  security_group_id = module.eks.cluster_primary_security_group_id
  referenced_security_group_id = data.terraform_remote_state.hub.outputs.hub_node_security_group_id
  ip_protocol = "tcp"
  from_port = "443"
  to_port = "443"
  
}

EOF
```

```bash
cd ~/environment/spoke
terraform init
terraform apply --auto-approve
```

The ArgoCD Dashboard should have the spoke-staging cluster

![Stagging Cluster](/static/images/spoke-staging-cluster.png)