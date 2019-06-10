terragrunt = {
  terraform {
    source = "github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v1.59.0"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

name = "shield"

tags = {
  Environment = "prod"
}