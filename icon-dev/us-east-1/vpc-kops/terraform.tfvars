terragrunt = {
  terraform {
    source = "github.com/robcxyz/terraform-aws-kops-vpc"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

service = "vpc"
name = "main-vpc"


