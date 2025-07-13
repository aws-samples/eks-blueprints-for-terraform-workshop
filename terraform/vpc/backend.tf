terraform {
  backend "s3" {
    # This will be configured dynamically
    # bucket = "your-terraform-state-bucket"
    # key    = "vpc/terraform.tfstate"
    # region = "us-east-1"
  }
}
