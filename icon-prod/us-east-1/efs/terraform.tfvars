terragrunt = {
  terraform {
    source = "../../../modules//efs"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = ["../vpc"]
  }
}

resource_group = "efs"
