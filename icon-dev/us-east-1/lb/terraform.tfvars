terragrunt = {
  terraform {
    source = "../../../modules//elb"
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
