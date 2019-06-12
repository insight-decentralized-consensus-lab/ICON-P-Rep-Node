terragrunt = {
  terraform {
    source = "../../../modules/p-rep"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../vpc"]
  }
}

resource_group = "p-rep-nodes"
volume_size = 50
instance_type = "t2.medium"
