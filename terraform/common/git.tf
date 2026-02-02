

# locals {
#   gitops_repos = {
#     retail-store-app-repo = {
#       name     = var.gitops_retail_store_app_repo_name
#       # basepath = var.gitops_addons_basepath
#       # path     = var.gitops_addons_path
#       # revision = var.gitops_addons_revision
#     }

#     retail-store-config-repo = {
#       name     = var.gitops_retail_store_config_repo_name
#       # basepath = var.gitops_workload_basepath
#       # path     = var.gitops_workload_path
#       # revision = var.gitops_workload_revision
#     }

#     platform-repo = {
#       name     = var.gitops_platform_repo_name
#       # basepath = var.gitops_platform_basepath
#       # path     = var.gitops_platform_path
#       # revision = var.gitops_platform_revision
#     }


#   }
#   gitea_user = var.gitea_user
#   gitea_password = var.gitea_password

#   git_secrets_version_locals = {
#     org         = "${var.gitea_external_url}"
#     repo_prefix = var.gitea_repo_prefix
#   }

#   git_secrets_urls  = { for repo_key, repo in local.gitops_repos : repo_key => "${local.git_secrets_version_locals.org}/${local.git_secrets_version_locals.repo_prefix}${repo.name}" }
#   git_secrets_names = { for repo_key, repo in local.gitops_repos : repo_key => "${local.context_prefix}-${repo_key}" }
# }


# resource "aws_secretsmanager_secret" "git_secrets" {
#   for_each                = local.gitops_repos
#   name                    = "${local.context_prefix}-${each.key}"
#   recovery_window_in_days = 0
# }

# resource "aws_secretsmanager_secret_version" "git_secrets_version" {
#   for_each  = aws_secretsmanager_secret.git_secrets
#   secret_id = each.value.id
#   secret_string = jsonencode({
#     username    = local.gitea_user
#     password    = local.gitea_password
#     url         = local.git_secrets_urls[each.key]
#     org         = local.git_secrets_version_locals.org
#     # repo        = "${local.git_secrets_version_locals.repo_prefix}${local.gitops_repos[each.key].name}"
#     # basepath    = local.gitops_repos[each.key].basepath
#     # path        = local.gitops_repos[each.key].path
#     # revision    = local.gitops_repos[each.key].revision
#   })
# }

# resource "aws_secretsmanager_secret" "argocd_workshop_repo_credentials" {
#   name        = "argocd_workshop_repo_credentials"
#   description = "Gitea repo credentials for Argo CD"
# }

# resource "aws_secretsmanager_secret_version" "argocd_workshop_repo_credentials" {
#   secret_id = aws_secretsmanager_secret.argocd_workshop_repo_credentials.id
#   secret_string = jsonencode({
#     username = local.gitea_user
#     token    = local.gitea_password
#   })
# }

# locals {
#     git_secrets_version_locals = {
#       org         = "${var.gitea_external_url}"
#       repo_prefix = var.gitea_repo_prefix
#     }  
# }

# resource "aws_secretsmanager_secret" "argocd_workshop_repo_org" {
#   name        = "argocd-workshop-repo"
#   description = "Gitea repo credentials for Argo CD"
# }

# resource "aws_secretsmanager_secret_version" "argocd_workshop_repo_org" {
#   secret_id = aws_secretsmanager_secret.argocd_workshop_repo_org.id
#   secret_string = jsonencode({
#     username    = var.gitea_user
#     token       = var.gitea_password
#     # url         = local.git_secrets_urls[each.key]
#     org           = local.git_secrets_version_locals.org
#     # repo        = "${local.git_secrets_version_locals.repo_prefix}${local.gitops_repos[each.key].name}"
#     # basepath    = local.gitops_repos[each.key].basepath
#     # path        = local.gitops_repos[each.key].path
#     # revision    = local.gitops_repos[each.key].revision
#   })
# }