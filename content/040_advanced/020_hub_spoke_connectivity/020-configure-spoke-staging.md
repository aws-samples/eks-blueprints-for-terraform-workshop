---
title: "Configure Spoke Staging"
weight: 20
---


### 1. Register the Spoke-Staging Cluster with the Hub's Argo CD

![Hub Role](/static/images/spoke-staging-secret.png)

The **hub-cluster** manages all Kubernetes clusters through its centralized Argo CD instance. To enable this, we’ll use **GitOps Bridge** to register the **spoke-staging** cluster by creating a remote cluster secret in the **hub-cluster**.

The Terraform code for the **spoke-staging** cluster can interact with the hub because we configure the Kubernetes provider with an alias (`kubernetes.hub`) to access the hub cluster.


:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='30'}
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
:::

Since the **spoke-staging** cluster is managed remotely, it does **not need its own Argo CD installation**. This is enforced by setting `install = false` (highlighted above).


### 2. Spoke Role to trust Hub Role

Next, we’ll create an IAM role for the **spoke-staging** cluster that allows the **hub cluster’s Argo CD** to assume it.


![Hub Role](/static/images/hub-spoke-spoke-role.png)

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

### 3. Grant Admin Access to the Spoke IAM Role

The spoke IAM role should have admin access on the Kubernetes cluster. This allows the Hub's Argo CD to deploy workloads, create namespaces, and install addons.

We’ll update the EKS module’s access_entries to grant admin access:

![Admin Policy](/static/images/spoke-staging-role-admin-policy.png)


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

Although the spoke cluster has public endpoint access, the DNS resolves to a private IP within the VPC. To allow the hub cluster's Argo CD pods to connect to the spoke cluster API, we need to open inbound port 443 in the spoke cluster's security group.

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
