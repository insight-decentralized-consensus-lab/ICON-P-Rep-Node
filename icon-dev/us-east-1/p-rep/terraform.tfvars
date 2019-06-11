terragrunt = {
  terraform {
    source = "../../p-rep-node"
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