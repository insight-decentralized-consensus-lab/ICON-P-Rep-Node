terragrunt = {
  terraform {
    source = "../../../modules//keys"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../iam"]
  }
}

resource_group = "keys"
