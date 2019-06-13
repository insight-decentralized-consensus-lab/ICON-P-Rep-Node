terragrunt = {
  terraform {
    source = "../../../modules//asg"
  }

  include {
    path = "${find_in_parent_folders()}"
  }
}

resource_group = "dns"

root_domain_name = "solidwallet.io"
subdomain = "insight"