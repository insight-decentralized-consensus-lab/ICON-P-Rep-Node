terragrunt = {
  terraform {
    source = "../../modules/security-groups"
  }

  include {
    path = "${find_in_parent_folders()}"
  }
}

