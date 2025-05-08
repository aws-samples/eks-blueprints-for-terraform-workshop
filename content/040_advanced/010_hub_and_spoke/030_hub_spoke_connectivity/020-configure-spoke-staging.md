---
title: "Configure Spoke Staging"
weight: 20
---

In the previous chapter, we created an IAM role for the Hub Cluster's Argo CD. Now, we'll create another IAM role (spoke) that can be assumed by the Hub Cluster's IAM role.

![Hub Role](/static/images/hub-spoke-spoke-role.jpg)

### 1. Create Argo CD spoke-staging cluster with hub-cluster

The Hub Cluster manages all cluster objects created in the Hub's Argo CD. The spoke-staging cluster should also be managed by the Hub's Argo CD. We'll use GitOps Bridge to create the spoke-staging cluster secret object in the hub cluster. The spoke Terraform can update the Hub because we configure the Kubernetes provider setting with `'kubernetes = kubernetes.hub'` to allow access.

Since the spoke cluster depends on the Hub's Argo CD, it doesn't need its own Argo CD installation. We can prevent Argo CD installation on the spoke by setting the GitOps bridge configuration `'install = false'`.

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

  # The Argo CD remote cluster secret is deploy on hub cluster not on spoke clusters
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

Let's create an IAM role for the spoke cluster that can be assumed by the Hub's Argo CD.

```bash

cat <<'EOF' >> ~/environment/spoke/variables.tf
variable "ssm_parameter_name_argocd_role_suffix" {
  description = "SSM parameter name for ArgoCD role"
  type        = string
  default     = "argocd-central-role"
}
EOF

cat <<'EOF' >> ~/environment/spoke/main.tf
# Reading parameter created by hub cluster to allow access of argocd to spoke clusters
data "aws_ssm_parameter" "argocd_hub_role" {
  name = "${local.context_prefix}-${var.ssm_parameter_name_argocd_role_suffix}"
}
EOF
```

Create Spoke Role, which allows assume role from Hub role:

```bash
cat <<'EOF' >> ~/environment/spoke/main.tf
################################################################################
# ArgoCD EKS Access
################################################################################
resource "aws_iam_role" "spoke" {
  name_prefix =  "${local.name}-argocd-spoke"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_ssm_parameter.argocd_hub_role.value]
    }
  }
}
EOF
```

### 3. Spoke Role to assume admin access on the spoke cluster

The spoke IAM role should have admin access on the spoke Kubernetes cluster. Since this role will be assumed by the Hub Argo CD to create addons, namespaces, and deploy workloads on the spoke cluster, it needs admin access. We'll add an additional rule in our EKS access entries:

```bash
sed -i '
/access_entries = {/,/^  }/ {
  s/workshop_attendee/eks_admin/
  /^  }/i\
\
    gitops_role = {\
      principal_arn     = aws_iam_role.spoke.arn\
      policy_associations = {\
        argocd = {\
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"\
          access_scope = {\
            type       = "cluster"\
          }\
        }\
      }\
    }
}
' ~/environment/spoke/main.tf
```

The code snippet above updates the access_entries section of the EKS module to grant admin access to the spoke IAM role.

### 4. Allow Hub Nodes to access the Spoke cluster

In this workshop, both the hub and spoke clusters reside within the same VPC. For Argo CD running on the hub cluster to manage the spoke cluster (creating namespaces, deploying add-ons, etc.), we need to configure the spoke cluster's security group to allow inbound traffic on port 443 from the hub cluster's node security group.

While the spoke cluster has public endpoint access, the endpoint hostname resolves to a private IP address within the VPC. By default, only nodes on the spoke cluster can connect to its API endpoint. To enable communication between the Argo CD Pods (app-controller and api-server) on the hub cluster and the spoke cluster's API endpoint, we'll create a security group rule allowing inbound traffic on port 443 from the hub cluster's node security group.

```bash
cat <<'EOF' >> ~/environment/spoke/main.tf

resource "aws_vpc_security_group_ingress_rule" "hub_to_spoke" {
  security_group_id = module.eks.cluster_primary_security_group_id
  referenced_security_group_id = data.terraform_remote_state.hub.outputs.cluster_node_security_group_id
  ip_protocol = "tcp"
  from_port = "443"
  to_port = "443"

}

EOF
```


### 5. Apply the changes

```bash
cd ~/environment/spoke
terraform init
terraform apply --auto-approve
```

### 6. Check Hub Cluster Configuration

The Hub Argo CD Dashboard should now include the spoke-staging cluster in its cluster list.

Connect again to the Hub Cluster Argo CD UI:

```bash
argocd_hub_credentials
```

And check the Settings / Clusters section:

![Stagging Cluster](/static/images/spoke-staging-cluster.png)
