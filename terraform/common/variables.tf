variable "project_context_prefix" {
  description = "Prefix for project"
  type        = string
  default     = "eks-fleet-workshop-gitops"
}

variable "secret_name_ssh_secrets" {
  description = "Secret name for SSH secrets"
  type        = string
  default     = "git-ssh-secrets-fleet-workshop"
}


variable "gitops_addons_repo_name" {
  description = "Git repository name for addons"
  default     = "eks-fleet-workshop-gitops-addons"
}
variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  default     = ""
}
variable "gitops_addons_path" {
  description = "Git repository path for addons"
  default     = "bootstrap"
}
variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  default     = "HEAD"
}

variable "gitops_platform_repo_name" {
  description = "Git repository name for platform"
  default     = "eks-fleet-workshop-gitops-platform"
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


variable "gitops_workload_repo_name" {
  description = "Git repository name for workload"
  default     = "eks-fleet-workshop-gitops-apps"
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

variable "ssm_parameter_name_argocd_role_suffix" {
  description = "SSM parameter name for ArgoCD role"
  type        = string
  default     = "argocd-central-role"
}


variable "gitea_user" {
  description = "User to login on the Gitea instance"
  type = string
  default = "workshop-user"
}
variable "gitea_password" {
  description = "Password to login on the Gitea instance"
  type = string
  sensitive = true
  default = ""
}
variable "gitea_external_url" {
  description = "External url to access gitea"
  type = string
  default = ""
}

variable "gitea_repo_prefix" {
  description = "Repo prefix"
  type = string
  default = "workshop-user/"
}

