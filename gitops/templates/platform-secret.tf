# resource "aws_secretsmanager_secret" "argocd_platform_repo_ssh" {
#   name        = "argocd_platform_repo_ssh"
#   description = "SSH key for Platform repo"
# }

# resource "aws_secretsmanager_secret_version" "argocd_platform_repo_ssh" {
#   secret_id     = aws_secretsmanager_secret.argocd_platform_repo_ssh.id
#   secret_string = file("~/.ssh/id_rsa")
# }

resource "aws_secretsmanager_secret" "platform_repo_credentials" {
  name        = "platform_repo_credentials"
  description = "Platform repo credentials for Argo CD"
}

resource "aws_secretsmanager_secret_version" "platform_repo_credentials" {
  secret_id = aws_secretsmanager_secret.platform_repo_credentials.id
  secret_string = jsonencode({
    username = "your-username"
    token    = "your-personal-access-token"
  })
}