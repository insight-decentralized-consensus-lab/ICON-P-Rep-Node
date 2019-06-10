terragrunt = {
  terraform {
    source = "github.com/robcxyz/terraform-aws-icon-p-rep"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../vpc"]
  }
}

service = "p-rep"

