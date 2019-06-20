terragrunt = {
  terraform {
    source = "../../../modules//ec2"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../efs",
      "../security_groups",
      "../keys"]
  }
}

resource_group = "ec2"
instance_type = "m4.large"
root_volume_size = 20
volume_path = "/dev/sdf"
volume_dir = ""

efs_directory = "/opt/data"
