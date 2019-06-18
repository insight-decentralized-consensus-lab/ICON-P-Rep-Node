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
instance_type = "c5.large"
ebs_volume_size = 100
root_volume_size = 8
