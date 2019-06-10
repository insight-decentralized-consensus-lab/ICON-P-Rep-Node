terragrunt = {
  terraform {
    source = "github.com/robcxyz/terraform-aws-kops-security-groups"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "vpc"]
  }
}

service = "security_groups"
