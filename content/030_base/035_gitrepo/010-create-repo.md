---
title: 'Create CodeCommit Repository'
weight: 10
---

### 1. Create Terraform project

```bash
mkdir -p ~/environment/codecommit
cd ~/environment/codecommit
```

Define Terraform and providers versions:

```bash
cat > ~/environment/codecommit/versions.tf << 'EOF'
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    random = {
      version = ">= 3"
    }
  }
}
EOF
```

### 2. Define variables

```bash
cat > ~/environment/codecommit/variables.tf << 'EOF'


variable "ssh_key_basepath" {
  description = "path to .ssh directory"
  type        = string
  default = "~/.ssh"
}

variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  default     = "addons/"
}
variable "gitops_addons_path" {
  description = "Git repository path for addons"
  default     = "applicationset/"
}
variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  default     = "HEAD"
}
variable "gitops_addons_repo_name" {
  description = "Git repository name for addons"
  default     = "gitops-platform"
}

variable "gitops_platform_basepath" {
  description = "Git repository base path for platform"
  default     = ""
}
variable "gitops_platform_path" {
  description = "Git repository path for workload"
  default     = "bootstrap"
}
variable "gitops_platform_revision" {
  description = "Git repository revision/branch/ref for workload"
  default     = "HEAD"
}
variable "gitops_platform_repo_name" {
  description = "Git repository name for platform"
  default     = "gitops-platform"
}

variable "gitops_workload_basepath" {
  description = "Git repository base path for workload"
  default     = ""
}
variable "gitops_workload_path" {
  description = "Git repository path for workload"
  default     = ""
}
variable "gitops_workload_revision" {
  description = "Git repository revision/branch/ref for workload"
  default     = "HEAD"
}
variable "gitops_workload_repo_name" {
  description = "Git repository name for workload"
  default     = "gitops-workload"
}

EOF
```

### 3. Create repositories 


```bash
cat > ~/environment/codecommit/main.tf <<'EOF'


data "aws_region" "current" {}

locals {

  context_prefix = "terraform-workshop"

  gitops_workload_repo_name = var.gitops_workload_repo_name
  gitops_workload_org       = "ssh://${aws_iam_user_ssh_key.gitops.id}@git-codecommit.${data.aws_region.current.id}.amazonaws.com"
  gitops_workload_repo      = "v1/repos/${local.gitops_workload_repo_name}"

  gitops_platform_repo_name = var.gitops_platform_repo_name
  gitops_platform_org       = "ssh://${aws_iam_user_ssh_key.gitops.id}@git-codecommit.${data.aws_region.current.id}.amazonaws.com"
  gitops_platform_repo      = "v1/repos/${local.gitops_platform_repo_name}"

  gitops_addons_repo_name = var.gitops_addons_repo_name
  gitops_addons_org       = "ssh://${aws_iam_user_ssh_key.gitops.id}@git-codecommit.${data.aws_region.current.id}.amazonaws.com"
  gitops_addons_repo      = "v1/repos/${local.gitops_addons_repo_name}"

  ssh_key_basepath           = var.ssh_key_basepath
  git_private_ssh_key        = "${local.ssh_key_basepath}/gitops_ssh.pem"
  git_private_ssh_key_config = "${local.ssh_key_basepath}/config"
  ssh_host                   = "git-codecommit.*.amazonaws.com"
  ssh_config                 = <<-EOF
  # AWS Workshop https://github.com/aws-samples/argocd-on-amazon-eks-workshop.git
  Host ${local.ssh_host}
    User ${aws_iam_user.gitops.unique_id}
    IdentityFile ${local.git_private_ssh_key}
  EOF

}

resource "aws_codecommit_repository" "workloads" {
  repository_name = local.gitops_workload_repo_name
  description     = "CodeCommit repository for ArgoCD workloads"
}

resource "aws_codecommit_repository" "platform" {
  repository_name = local.gitops_platform_repo_name
  description     = "CodeCommit repository for ArgoCD platform"
}


resource "aws_iam_user" "gitops" {
  name = "${local.context_prefix}-gitops"
  path = "/"
}

resource "aws_iam_user_ssh_key" "gitops" {
  username   = aws_iam_user.gitops.name
  encoding   = "SSH"
  public_key = tls_private_key.gitops.public_key_openssh
}

resource "tls_private_key" "gitops" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_string" "secret_suffix" {
  length  = 5     # Length of the random string
  special = false # Set to true if you want to include special characters
  upper   = true  # Set to true if you want uppercase letters in the string
  lower   = true  # Set to true if you want lowercase letters in the string
  number  = true  # Set to true if you want numbers in the string
}
resource "aws_secretsmanager_secret" "codecommit_key" {
  name = "codecommit-key-${random_string.secret_suffix.result}"
}

resource "aws_secretsmanager_secret_version" "private_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.codecommit_key.id
  secret_string = tls_private_key.gitops.private_key_pem
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.gitops.private_key_pem
  filename        = pathexpand(local.git_private_ssh_key)
  file_permission = "0600"
}

resource "local_file" "ssh_config" {
  count           = local.ssh_key_basepath == "/home/ec2-user/.ssh" ? 1 : 0
  content         = local.ssh_config
  filename        = pathexpand(local.git_private_ssh_key_config)
  file_permission = "0600"
}

resource "null_resource" "append_string_block" {
  count = local.ssh_key_basepath == "/home/ec2-user/.ssh" ? 0 : 1
  triggers = {
    always_run = "${timestamp()}"
    file       = pathexpand(local.git_private_ssh_key_config)
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOL
      start_marker="### START BLOCK AWS Workshop ###"
      end_marker="### END BLOCK AWS Workshop ###"
      block="$start_marker\n${local.ssh_config}\n$end_marker"
      file="${self.triggers.file}"

      if ! grep -q "$start_marker" "$file"; then
        echo "$block" >> "$file"
      fi
    EOL
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOL
      start_marker="### START BLOCK AWS Workshop ###"
      end_marker="### END BLOCK AWS Workshop ###"
      file="${self.triggers.file}"

      if grep -q "$start_marker" "$file"; then
        sed -i '' "/$start_marker/,/$end_marker/d" "$file"
      fi
    EOL

  }
}


data "aws_iam_policy_document" "gitops_access" {
  statement {
    sid = ""
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush"
    ]
    effect = "Allow"
    resources = [
      aws_codecommit_repository.workloads.arn,
      aws_codecommit_repository.platform.arn,
    ]
  }
}

resource "aws_iam_policy" "gitops_access" {
  name   = "${local.context_prefix}-gitops"
  path   = "/"
  policy = data.aws_iam_policy_document.gitops_access.json
}

resource "aws_iam_user_policy_attachment" "gitops_access" {
  user       = aws_iam_user.gitops.name
  policy_arn = aws_iam_policy.gitops_access.arn
}


EOF
```

### 3. Create outputs

VPC and private subnets are used when creating EKS Clusters.

```bash
cat > ~/environment/codecommit/outputs.tf <<'EOF'
output "configure_argocd" {
  value = "argocd repo add ${local.gitops_workload_org}/${local.gitops_workload_repo} --ssh-private-key-path $${HOME}/.ssh/gitops_ssh.pem --insecure-ignore-host-key --upsert --name git-repo"
}
output "git_clone" {
  value = "git clone ${local.gitops_workload_org}/${local.gitops_workload_repo}"
}
output "ssh_config" {
  value = local.ssh_config
}
output "ssh_host" {
  value = local.ssh_host
}

output "git_private_ssh_key" {
  value = local.git_private_ssh_key
}

output "gitops_addons_url" {
  value = "${local.gitops_addons_org}/${local.gitops_addons_repo}"
}
output "gitops_addons_org" {
  description = "Git repository org/user contains for addons"
  value       = local.gitops_addons_org
}
output "gitops_addons_repo" {
  description = "Git repository contains for addons"
  value       = local.gitops_addons_repo
}
output "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  value       = var.gitops_addons_basepath
}
output "gitops_addons_path" {
  description = "Git repository path for addons"
  value       = var.gitops_addons_path
}
output "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  value       = var.gitops_addons_revision
}

output "gitops_platform_url" {
  value = "${local.gitops_platform_org}/${local.gitops_platform_repo}"
}
output "gitops_platform_org" {
  description = "Git repository org/user contains for platform"
  value       = local.gitops_platform_org
}
output "gitops_platform_repo" {
  description = "Git repository contains for platform"
  value       = local.gitops_workload_repo
}
output "gitops_platform_basepath" {
  description = "Git repository base path for platform"
  value       = var.gitops_platform_basepath
}
output "gitops_platform_path" {
  description = "Git repository path for platform"
  value       = var.gitops_platform_path
}
output "gitops_platform_revision" {
  description = "Git repository revision/branch/ref for platform"
  value       = var.gitops_platform_revision
}

output "gitops_workload_url" {
  value = "${local.gitops_workload_org}/${local.gitops_workload_repo}"
}
output "gitops_workload_org" {
  description = "Git repository org/user contains for workload"
  value       = local.gitops_workload_org
}
output "gitops_workload_repo" {
  description = "Git repository contains for workload"
  value       = local.gitops_workload_repo
}
output "gitops_workload_basepath" {
  description = "Git repository base path for workload"
  value       = var.gitops_workload_basepath
}
output "gitops_workload_path" {
  description = "Git repository path for workload"
  value       = var.gitops_workload_path
}
output "gitops_workload_revision" {
  description = "Git repository revision/branch/ref for workload"
  value         = var.gitops_workload_revision
}
output "codecommit_key_id" {
  description = "Secret name that holds the SSH key for accessing CodeCommit"
  value       = aws_secretsmanager_secret.codecommit_key.id
}
output "codecommit_key_name" {
  description = "Secret name that holds the SSH key for accessing CodeCommit"
  value       = aws_secretsmanager_secret.codecommit_key.name
}

EOF
```
```bash
cd ~/environment/codecommit
terraform init
terraform apply --auto-approve
```

## Populate git repositories

### 1 Set environment variables

```bash
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export WORKING_DIR="$HOME/environment"
export SOURCE_DIR="source"
export WORKSHOP_DIR="$WORKING_DIR/$SOURCE_DIR"
export GITOPS_DIR="$WORKING_DIR/gitops-repos"

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" | tee -a ~/.bash_profile
echo "export WORKING_DIR=${WORKING_DIR}" | tee -a ~/.bash_profile
echo "export SOURCE_DIR=${SOURCE_DIR}" | tee -a ~/.bash_profile
echo "export WORKSHOP_DIR=${WORKSHOP_DIR}" | tee -a ~/.bash_profile
echo "export GITOPS_DIR=${GITOPS_DIR}" | tee -a ~/.bash_profile
source ~/.bash_profile

```



### 2 Clone source workload and platform

```bash
cd $WORKING_DIR
git clone --depth 1 --no-checkout https://github.com/aws-samples/eks-blueprints-for-terraform-workshop $SOURCE_DIR
cd $WORKSHOP_DIR
git sparse-checkout set assets 
git checkout
cd $WORKING_DIR

```

### 3 Populate codecommit platform repository


```bash
mkdir -p ${GITOPS_DIR}
gitops_platform_url=https://git-codecommit.${AWS_DEFAULT_REGION}.amazonaws.com/v1/repos/gitops-platform
# populate platform repository
git clone ${gitops_platform_url} ${GITOPS_DIR}/platform
cp -r $WORKSHOP_DIR/assets/platform/* ${GITOPS_DIR}/platform
cd ${GITOPS_DIR}/platform
#mkdir -p ${GITOPS_DIR}/platform/charts && cp -r ${WORKSHOP_DIR}/gitops/platform/charts/* ${GITOPS_DIR}/platform/charts/
#mkdir -p ${GITOPS_DIR}/platform/bootstrap && cp -r ${WORKSHOP_DIR}/gitops/platform/bootstrap/* ${GITOPS_DIR}/platform/bootstrap/
git -C ${GITOPS_DIR}/platform add .  || true
git -C ${GITOPS_DIR}/platform commit -m "initial commit" || true
git -C ${GITOPS_DIR}/platform push || true

```



### 3 Populate codecommit workload repository


```bash
cd ~/environment
gitops_workload_url=https://git-codecommit.${AWS_DEFAULT_REGION}.amazonaws.com/v1/repos/gitops-workload
# populate workload repository
git clone ${gitops_workload_url} ${GITOPS_DIR}/workload
cp -r $WORKSHOP_DIR/assets/workload/* ${GITOPS_DIR}/workload
cd ${GITOPS_DIR}/workload
git -C ${GITOPS_DIR}/workload add .  || true
git -C ${GITOPS_DIR}/workload commit -m "initial commit" || true
git -C ${GITOPS_DIR}/workload push || true

```