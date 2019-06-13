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
volume_size = 50
instance_type = "t2.micro"
