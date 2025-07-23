data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    bucket = "${data.aws_ssm_parameter.tfstate_bucket.value}"
    key    = "common/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

data "aws_ssm_parameter" "tfstate_bucket" {
  name = "eks-blueprints-workshop-tf-backend-bucket"
}
