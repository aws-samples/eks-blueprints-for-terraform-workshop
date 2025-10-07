---
title: "Configure Spoke Cluster"
weight: 20
---

<!-- cspell:disable-next-line -->

::video{id=9_1kx8TW1do}

In this chapter, you will configure the spoke-staging cluster so that it can be registered as a managed cluster in the hub Argo CD instance. This allows Argo CD running in the hub cluster to deploy workloads to the spoke.

### 1. Spoke-Staging Access to Hub Cluster

The spoke-staging Terraform needs access to the hub cluster to register itself (Argo CD cluster object) as a managed cluster.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml}
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
EOF
:::
<!-- prettier-ignore-end -->

### 2. Retrieve Hub Role ARN

Retrieve the hub role ARN from the SSM parameter. This role is required in the trust policy for the spoke cluster’s IAM role.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml}
cat <<'EOF' >> ~/environment/spoke/variables.tf
variable "ssm_parameter_name_argocd_role_suffix" {
  description = "SSM parameter name for Argo CD role"
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
:::
<!-- prettier-ignore-end -->

### 3. Create Spoke Role

![Staging Cluster Role](/static/images/hub-spoke-spoke-role.png)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='15'}
cat <<'EOF' >> ~/environment/spoke/main.tf
################################################################################
# Argo CD EKS Access
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

:::
<!-- prettier-ignore-end -->

Line 15: Spoke role Trust's hub role

### 4. Grant Admin Access

Grant Cluster Admin access to the spoke role.

![Staging Cluster Role Admin Access](/static/images/hub-spoke-spoke-role-admin-access.png)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml}
sed -i '
/access_entries = {/,/^  }/ {
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
:::
<!-- prettier-ignore-end -->

### 5. Register Spoke-Staging cluster with Hub Argo CD

![Staging Cluster Registration](/static/images/hub-spoke-cluster-object.png)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='14'}
cat <<'EOF' >> ~/environment/spoke/main.tf
################################################################################
# GitOps Bridge: Bootstrap for Hub Cluster
################################################################################
module "gitops_bridge_bootstrap_hub" {
  source  = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"

  # The Argo CD remote cluster secret is deployed on the hub cluster, not on spoke clusters
  providers = {
    kubernetes = kubernetes.hub
  }

  install = false # We are not installing argocd via helm on hub cluster
  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = local.environment
    metadata     = local.annotations
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
<!-- prettier-ignore-end -->

Line 15: Does not install Argo CD on the spoke cluster

### 6. Allow Hub Nodes to access the Spoke cluster

Although the spoke cluster has public endpoint access, the DNS resolves to a private IP within the VPC. To allow the hub cluster's Argo CD pods to connect to the spoke cluster API, we need to open inbound port 443 in the spoke cluster's security group.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml}

cat <<'EOF' >> ~/environment/spoke/main.tf

resource "aws_vpc_security_group_ingress_rule" "hub_to_spoke" {
  security_group_id            = module.eks.cluster_primary_security_group_id
  referenced_security_group_id = data.terraform_remote_state.hub.outputs.cluster_primary_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = "443"
  to_port                      = "443"
}

EOF
:::
<!-- prettier-ignore-start -->

### 7. Configure Hub Remote state

We need to reference outputs from the hub module for hub-spoke connectivity in the spoke-staging cluster.
<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml}
cat <<'EOF' >> ~/environment/spoke/remote_state.tf
data "terraform_remote_state" "hub" {
  backend = "s3"

  config = {
    bucket = "${data.aws_ssm_parameter.tfstate_bucket.value}"
    key    = "hub/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
EOF
:::
<!-- prettier-ignore-start -->

### 8. Apply the changes

<!-- prettier-ignore-start -->

:::code{showCopyAction=true showLineNumbers=false language=yaml}
cd ~/environment/spoke
terraform init
terraform workspace select staging
terraform apply --auto-approve
:::

<!-- prettier-ignore-end -->

### 9. Check Hub Cluster Configuration

After applying the changes, the spoke-staging cluster should appear in the Settings → Clusters section of the Argo CD UI running on the hub cluster.

![Staging Cluster](/static/images/spoke-staging-cluster.png)
