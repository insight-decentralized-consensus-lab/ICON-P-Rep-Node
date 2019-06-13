terragrunt = {
  terraform {
    source = "../../../modules//iam"
  }

  include {
    path = "${find_in_parent_folders()}"
  }
}

resource_group = "iam"