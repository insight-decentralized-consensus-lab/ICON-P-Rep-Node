terragrunt = {
  terraform {
    source = "../../../modules//lb"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../vpc"]
  }
}

resource_group = "elb"
