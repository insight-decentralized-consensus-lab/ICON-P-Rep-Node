terragrunt = {
  terraform {
    source = "github.com/robcxyz/terraform-aws-kops-run"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../vpc"]
  }
}

service = "kops"

