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
root_volume_size = 8
volume_path = "/dev/sdf"
volume_dir = ""