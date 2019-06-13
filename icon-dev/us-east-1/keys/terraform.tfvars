terragrunt = {
  terraform {
    source = "../../../modules//keys"
  }

  include {
    path = "${find_in_parent_folders()}"
  }
}

resource_group = "keys"
