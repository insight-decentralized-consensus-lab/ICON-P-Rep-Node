terragrunt = {
  terraform {
    source = "../../../modules//security_groups"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../vpc"]
  }
}

