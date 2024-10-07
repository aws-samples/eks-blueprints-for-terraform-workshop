---
title: "Configure Spoke Staging"
weight: 20
---

In the previous chapter, an IAM role was created for the Hub Cluster's Argo CD. In this chapter, another IAM role (spoke) will be created that can be assumed by the Hub Cluster's IAM role.

![Hub Role](/static/images/hub-spoke-spoke-role.jpg)

### 1. Create Argo CD spoke-staging cluster with hub-cluster

The Hub Cluster manages all cluster objects created in the Hub's Argo CD. The spoke-staging cluster should also be managed by the Hub's Argo CD. Use GitOps Bridge to create the spoke-staging cluster secret object in the hub cluster. The spoke Terraform can update the Hub because we configure the Kubernetes provider setting with `'kubernetes = kubernetes.hub'` to allows access.

The spoke cluster does not need its own Argo CD installation since it depends on the Hub's Argo CD. You can prevent Argo CD installation on the spoke by setting the GitOps bridge configuration `'install = false'`.

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

Create an IAM role for the spoke cluster that can be assumed by the Hub's Argo CD.

```bash
cat <<'EOF' >> ~/environment/spoke/main.tf
################################################################################
# Argo CD EKS Access
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

The spoke IAM role should have admin access on the spoke Kubernetes cluster. This spoke IAM role will be assumed by the Hub Argo CD. It needs admin access in order to create addons, namespaces, and deploy workloads on the spoke cluster. For that, we add an additional rule in our EKS access entries:

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

The code snippet above update the access_entries section of eks module to grant admin access to the spoke IAM role.

### 4. Allow Hub Nodes to access to Spoke cluster

In this workshop, the hub and spoke clusters reside within the same VPC. The Argo CD instance running on the hub cluster needs to communicate with the spoke Kubernetes cluster to create namespaces, deploy add-ons, and manage resources. To enable this communication, we need to configure the security group associated with the spoke cluster to allow inbound traffic on port 443 from the security group of the hub cluster's nodes.

Specifically, we need to allow the Argo CD Pods (app-controller and api-server) on the hub cluster to connect to the EKS spoke cluster's endpoint. Although the spoke cluster has public endpoint access, the endpoint hostname resolves to the private IP address within the VPC. By default, the security group only allows nodes on the spoke cluster to connect to its API endpoint.

To resolve this, we will create a new security group rule that permits inbound traffic on port 443 from the security group associated with the hub cluster's nodes. This will enable the Argo CD Pods on the hub cluster to communicate with the spoke cluster's API endpoint within the VPC, facilitating centralized management and deployment across multiple clusters.

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

```bash
cd ~/environment/spoke
terraform init
terraform apply --auto-approve
```

### 5. Check Hub Cluster Configuration

The Hub Argo CD Dashboard should have the spoke-staging cluster in it's cluster list.

Connect again to the Hub Cluster Argo CD UI:

```bash
argocd_hub_credentials
```

And check the Settings / Clusters section:

![Stagging Cluster](/static/images/spoke-staging-cluster.png)
