data "aws_ssm_parameter" "tfstate_bucket" {
  name = "eks-blueprints-workshop-tf-backend-bucket"
}
