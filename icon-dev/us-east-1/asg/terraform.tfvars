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


grpc_listener_port = 7100
grpc_target_group_sticky = ""
grpc_target_group_path = ""
grpc_target_group_port = 7100

rest_listener_port = 9000
rest_target_group_sticky = ""
rest_target_group_path = ""
rest_target_group_port = 9000
