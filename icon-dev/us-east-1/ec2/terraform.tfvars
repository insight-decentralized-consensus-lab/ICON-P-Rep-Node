terragrunt = {
  terraform {
    source = "../../../modules//ec2"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../vpc",
      "../security_groups",
      "../keys"]
  }
}

resource_group = "ec2"
volume_size = 100
instance_type = "c5n.large"
