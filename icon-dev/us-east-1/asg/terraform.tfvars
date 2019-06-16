terragrunt = {
  terraform {
    source = "../../../modules//asg"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../vpc",
      "../logs",
      "../security_groups",
      "../keys"]
  }
}

resource_group = "asg"
volume_size = 100
instance_type = "c5n.large"
