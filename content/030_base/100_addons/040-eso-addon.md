---
title: "Install External Secrets Operator(ESO) Addon"
weight: 40
---

Some addons require IAM roles to access AWS services.
* External Secrets Operator (ESO) – needs IAM role to access AWS Secrets Manager
* Karpenter – requires IAM role to access EC2 API
* Cert-manager – requires IAM role to access AWS Certificate Manager (ACM)


In this chapter, we will deploy the External Secrets Operator (ESO) to access AWS Secrets Manager. ESO will use Pod Identity to securely authenticate and retrieve secrets from AWS.

![ESO](/static/images/eso.png)


### 1 Enable the ESO Add-on with a Label
This can be installed by setting label enable_external_secrets = true

:::code{showCopyAction=true language=json highlightLines='4'}
sed -i '
/addons = {/,/}/ {
    /}/ i\
    enable_external_secrets = true
}
' ~/environment/hub/terraform.tfvars
:::



### 2. Associate an IAM Role with the ESO Service Account

The following code creates Pod Identity for ESO Service Account.

:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/main.tf

locals {
  external_secrets = {
    namespace       = "external-secrets"
    service_account = "external-secrets-sa"
  }
}
module "external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name = "external-secrets"

  attach_external_secrets_policy        = true
  external_secrets_ssm_parameter_arns   = ["arn:aws:ssm:*:*:parameter/*"]         # In case you want to restrict access to specific SSM parameters "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/${local.name}/*"
  external_secrets_secrets_manager_arns = ["arn:aws:secretsmanager:*:*:secret:*"] # In case you want to restrict access to specific Secrets Manager secrets "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:${local.name}/*"
  external_secrets_kms_key_arns         = ["arn:aws:kms:*:*:key/*"]               # In case you want to restrict access to specific KMS keys "arn:aws:kms:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:key/*"
  external_secrets_create_permission    = false

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = local.external_secrets.namespace
      service_account = local.external_secrets.service_account
    }
  }

  tags = local.tags
}
EOF
:::

### 3. Add ESO Service Account Annotations

The GitOps Bridge uses annotations to determine the name and namespace of the ESO service account to create. If annotations are not provided, it falls back to default values defined in the Helm chart.

The following code uncomments to add annotation to the hub cluster.

:::code{showCopyAction=true showLineNumbers=false language=json }
sed -i "s/#enableeso//g" ~/environment/hub/main.tf
:::

Uncommenting code shows as below

:::code{showCopyAction=false showLineNumbers=false language=json highlightLines='5,6' }
  annotations = merge(
    .
    .
    {
      external_secrets_service_account = local.external_secrets.service_account
      external_secrets_namespace = local.external_secrets.namespace
    }
    .
    .   
  ) 
:::

:::alert{header="Note" type="info"}

You can also use the Terraform EKS Blueprints addons module eks_blueprints_addons  to automatically provision least privilege roles for each addon.

This module allows both installing the addons and creating their IAM roles. However, we only want it to create the IAM roles, not deploy the addons themselves. The installation of the addons onto the EKS cluster is done by Argo CD.

Using the EKS Blueprint Addons module improves security and reduces complexity.

We configure the Terraform module to create only the required AWS resources but not the Kubernetes resources (as we prefer to let Argo CD manage Kubernetes resources) by setting create_kubernetes_resources = false.
:::

### 4. Terraform Apply

:::code{showCopyAction=true language=json }
cd ~/environment/hub
terraform init
terraform apply --auto-approve
:::


### 5. Validate the ESO Add-on

:::alert{header="Sync Application"}
If the new addon-external-secrets-hub-cluster is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.

Or you can do it also with cli:

```bash
argocd app sync argocd/cluster-addons
```

:::

We already have Gittea repository information in AWS Secret Manager. We will create an External Secret to copy from AWS Secret eks-blueprints-workshop-gitops-addons to Kubernetes secret-addon secret.

:::code{showCopyAction=true language=json }
mkdir ~/environment/basic
cat <<'EOF' >> ~/environment/basic/eso.yaml

apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: default
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: service-addon
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: secret-addon
    creationPolicy: Owner
  dataFrom:
  - extract:
      key: "eks-blueprints-workshop-gitops-addons"
EOF
:::

Create External Secret

:::code{showCopyAction=true language=json }
kubectl apply -f ~/environment/basic/eso.yaml
:::

:::alert{header="Sync Application"}
If you see an error like "Error from server (InternalError): error when creating" then it is still creating ESO controller. Give it a couple of minutes and execute below command again. 

```bash
kubectl apply -f ~/environment/basic/eso.yaml
```
:::

Validate Kubernetes Secret
:::code{showCopyAction=true language=json }
kubectl get secrets secret-addon -oyaml
:::

You can see eks-blueprints-workshop-gitops-addons secrets copied under data: section in encoded in base64.