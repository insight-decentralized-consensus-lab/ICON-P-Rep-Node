terragrunt = {
  terraform {
    source = "../../../modules//ebs"
  }

  include {
    path = "${find_in_parent_folders()}"
  }
}

resource_group = "ebs"
ebs_volume_size = 100

