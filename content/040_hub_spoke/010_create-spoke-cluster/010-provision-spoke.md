---
title: "Create Spoke Staging Cluster"
weight: 10
---

::video{id=rLwkZmxfK88}

The **spoke-staging cluster** has a configuration similar to the **hub-cluster**. In this step, we'll copy the Terraform configuration from the hub-cluster and update it where necessary to create our staging spoke cluster.


### 1. Configure Remote state

We need to reference outputs from the VPC module (for subnets) and the hub module (for hub-spoke connectivity) in the spoke-staging cluster.


<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
mkdir -p ~/environment/spoke
cd ~/environment/spoke
cat > ~/environment/spoke/remote_state.tf << 'EOF'
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/../vpc/terraform.tfstate"
  }
}
data "terraform_remote_state" "hub" {
  backend = "local"

  config = {
    path = "${path.module}/../hub/terraform.tfstate"
  }
}

EOF
:::
<!-- prettier-ignore-end -->

### 2. Configure EKS Spoke cluster

We’ll reuse the Terraform configuration from the hub cluster with a few changes:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='17,27,30'}
cp ~/environment/hub/git_data.tf ~/environment/spoke
cp ~/environment/hub/main.tf ~/environment/spoke
cp ~/environment/hub/variables.tf ~/environment/spoke
cp ~/environment/hub/outputs.tf ~/environment/spoke
cp ~/environment/hub/versions.tf ~/environment/spoke
sed -i 's/hub-cluster/spoke-${terraform.workspace}/g' ~/environment/spoke/main.tf
sed -i 's/environment = "dev"/environment = terraform.workspace/' ~/environment/spoke/main.tf
sed -i 's/fleet_member = "hub"/fleet_member = "spoke"/' ~/environment/spoke/main.tf

sed -i 's/{ workload_webstore = true }/{ workload_webstore = false }/' ~/environment/spoke/main.tf

# Clean some parts
sed -i 's/^    bootstrap   = file("${path.module}\/bootstrap\/bootstrap-applicationset.yaml")/#    bootstrap   = file("${path.module}\/bootstrap\/bootstrap-applicationset.yaml")/' ~/environment/spoke/main.tf
sed -i '/^module "gitops_bridge_bootstrap" {/,/^}/d' ~/environment/spoke/main.tf
sed -i '/^resource "kubernetes_secret" "git_secrets" {/,/^}/d' ~/environment/spoke/main.tf
:::
<!-- prettier-ignore-start -->

Changes made to the hub-cluster Terraform configuration:
 
Line 5: Rename cluster from hub-cluster to spoke-${terraform.workspace}. The workspace "staging" will be created in a later step.  
Line 6: Set label environment=staging.  
Line 7: Set lable fleet_member=spoke.  
Line 9: Set lable workload_webstore=false. This will be set to true during applicationd deployment in the latter chapter.
Line 12–14: Disable the bootstrap ApplicationSet and remove the GitOps Bridge module (we don’t deploy Argo CD on spoke-staging cluster).

### 3. Configure addons

Copy the .tfvars file and disable Argo CD and other optional components:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
cp ~/environment/hub/terraform.tfvars ~/environment/spoke/terraform.tfvars
sed -i 's/enable_argocd = true/enable_argocd = false/' ~/environment/spoke/terraform.tfvars
sed -i 's/enable_ingress_nginx = true/enable_ingress_nginx = false/' ~/environment/spoke/terraform.tfvars
sed -i 's/enable_external_secrets = true/enable_external_secrets = false/' ~/environment/spoke/terraform.tfvars
:::
<!-- prettier-ignore-end -->

### 4. Create Terraform workspace & Apply Terraform

Create a new staging workspace and apply the configuration:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
cd ~/environment/spoke
terraform workspace new staging
terraform init
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->


::alert[The process of creating the cluster typically requires approximately 15 minutes to complete.]{header="Wait for resources to create"}

### 5. Access Spoke Staging Cluster

To configure kubectl, we will execute:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
eval $(terraform output -raw configure_kubectl)
:::
<!-- prettier-ignore-end -->

To verify that kubectl is correctly configured, run:


<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
kubectl get svc --context spoke-staging
:::
<!-- prettier-ignore-end -->

To verify that kubectl is correctly configured, run the command below to see if the API endpoint is reachable.

Expected output:

```
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   172.20.0.1   <none>        443/TCP   2d
```

We can now see our spoke-staging cluster in the AWS Console under EKS > Clusters.
