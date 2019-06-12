terragrunt = {
  terraform {
    source = "../../../modules/iam"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../vpc"]
  }
}

resource_group = "iam"