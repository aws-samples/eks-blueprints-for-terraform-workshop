---
title: "Create Spoke Staging Cluster"
weight: 10
---

### 1. Remote state

The spoke-staging cluster references outputs from the vpc and hub modules.

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

It configures the EKS cluster, sets up label and annotation values, and uses the Terraform blueprint addons module to create IAM roles.

```bash
cp ~/environment/hub/git_data.tf ~/environment/spoke
cp ~/environment/hub/main.tf ~/environment/spoke
sed -i 's/hub-cluster/spoke-${terraform.workspace}/g' ~/environment/spoke/main.tf
sed -i 's/environment     = "hub"/environment     = terraform.workspace/' ~/environment/spoke/main.tf

sed -i 's/^    bootstrap   = file("${path.module}\/bootstrap\/bootstrap-applicationset.yaml")/#    bootstrap   = file("${path.module}\/bootstrap\/bootstrap-applicationset.yaml")/' ~/environment/spoke/main.tf

```

### 3. Define variables

```bash
cp ~/environment/hub/variables.tf ~/environment/spoke
```

### 4. Define outputs

```bash
cp ~/environment/hub/outputs.tf ~/environment/spoke
```

### 5. Copy variable values file to the cluster

We copy and reset the addons, so that we enable when required.
We copy the terraform configuration file to define the variable, but we deactivate Argo CD, as we don't want to deploy it on spoke cluster.

```bash
cp ~/environment/terraform.tfvars ~/environment/spoke/terraform.tfvars
sed -i 's/enable_aws_argocd = true/enable_aws_argocd = false/' ~/environment/spoke/terraform.tfvars
```

### 6. Create terraform workspace & Apply Terraform

Create new staging workspace

```bash
cd ~/environment/spoke
```

### 7. Apply Terraform

```bash
cd ~/environment/spoke
terraform workspace new staging
terraform init
terraform apply --auto-approve
```

::alert[The process of creating the cluster typically requires approximately 15 minutes to complete.]{header="Wait for resources to create"}

### 8. Access Spoke Staging Cluster

To configure kubectl, execute the following:

```bash
eval $(terraform output -raw configure_kubectl)
```

Run the command below to see the nodes in the hub cluster.

```bash
kubectl get nodes --context spoke-staging
```

Expected output:

```
NAME                                        STATUS   ROLES    AGE   VERSION
ip-10-0-40-218.eu-west-1.compute.internal   Ready    <none>   19m   v1.28.13-eks-a737599
ip-10-0-44-149.eu-west-1.compute.internal   Ready    <none>   19m   v1.28.13-eks-a737599
ip-10-0-49-157.eu-west-1.compute.internal   Ready    <none>   19m   v1.28.13-eks-a737599
```

Navigate to the AWS Console, go to EKS, then select Clusters to see the spoke-staging cluster.
