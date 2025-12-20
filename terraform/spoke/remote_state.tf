data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "${data.aws_ssm_parameter.tfstate_bucket.value}"
    key    = "vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

# data "terraform_remote_state" "hub" {
#   backend = "s3"

#   config = {
#     bucket = "${data.aws_ssm_parameter.tfstate_bucket.value}"
#     key    = "hub/terraform.tfstate"
#     region = data.aws_region.current.name
#   }
# }


data "aws_ssm_parameter" "tfstate_bucket" {
  name = "eks-blueprints-workshop-tf-backend-bucket"
}
