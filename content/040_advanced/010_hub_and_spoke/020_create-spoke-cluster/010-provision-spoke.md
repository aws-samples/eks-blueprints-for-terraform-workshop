---
title: "Create Spoke Staging Cluster"
weight: 10
---

### 1. Remote state

We need to reference outputs from the vpc and hub modules for our spoke-staging cluster.

```bash
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
```

### 2. Configure EKS Spoke cluster

Let's reuse the Terraform configuration from the hub cluster with some modifications for our spoke cluster:

```bash
cp ~/environment/hub/git_data.tf ~/environment/spoke
cp ~/environment/hub/main.tf ~/environment/spoke
sed -i 's/hub-cluster/spoke-${terraform.workspace}/g' ~/environment/spoke/main.tf
sed -i 's/environment     = "control-plane"/environment     = terraform.workspace/' ~/environment/spoke/main.tf
sed -i 's/fleet_member     = "control-plane"/fleet_member     = "spoke"/' ~/environment/spoke/main.tf

sed -i '
s/{ workloads = true },/{ workloads = false },/
s/{ workload_webstore = true }/{ workload_webstore = false }/
' ~/environment/spoke/main.tf

# Clean some parts
sed -i 's/^    bootstrap   = file("${path.module}\/bootstrap\/bootstrap-applicationset.yaml")/#    bootstrap   = file("${path.module}\/bootstrap\/bootstrap-applicationset.yaml")/' ~/environment/spoke/main.tf
sed -i '/^module "gitops_bridge_bootstrap" {/,/^}/d' ~/environment/spoke/main.tf
```

### 3. Define variables

```bash
cp ~/environment/hub/variables.tf ~/environment/spoke
```

### 4. Define outputs

```bash
cp ~/environment/hub/outputs.tf ~/environment/spoke
```

### 5. Configure addons

We will copy the Terraform configuration but disable Argo CD since we do not want to deploy it on the spoke cluster:

```bash
cp ~/environment/hub/terraform.tfvars ~/environment/spoke/terraform.tfvars
sed -i 's/enable_argocd = "true"/enable_argocd = "false"/' ~/environment/spoke/terraform.tfvars
```

### 6. Create Terraform workspace & Apply Terraform

Let's create a new staging workspace and initialize our configuration:

```bash
cd ~/environment/spoke
terraform workspace new staging
terraform init
terraform apply --auto-approve
```

::alert[The process of creating the cluster typically requires approximately 15 minutes to complete.]{header="Wait for resources to create"}

### 7. Access Spoke Staging Cluster

To configure kubectl, we will execute:

```bash
eval $(terraform output -raw configure_kubectl)
```

To verify that kubectl is correctly configured, run the command below to see the nodes in the EKS cluster. 

```bash
kubectl get nodes --context hub-cluster
```

Since there is no workload deployed, no nodes have been created to host that workload. However, the fact that no nodes were created does validate that the system can access the cluster.

Expected output:

```
No resources found
```

We can now see our spoke-staging cluster in the AWS Console under EKS > Clusters.
