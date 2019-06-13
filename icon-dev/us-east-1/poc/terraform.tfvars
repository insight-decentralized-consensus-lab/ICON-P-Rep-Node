terragrunt = {
  terraform {
    source = "../../../modules//poc"
  }

  include {
    path = "${find_in_parent_folders()}"
  }
}

resource_group = "poc"
