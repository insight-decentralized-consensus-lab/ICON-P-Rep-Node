//terragrunt = {
//  terraform {
//    source = "../../../modules//alb"
//  }
//
//  include {
//    path = "${find_in_parent_folders()}"
//  }
//
//  dependencies {
//    paths = [
//      "../vpc",
//      "../logs",
//      "../security_groups",
//      "../keys",
//      "../asg",
//      "../iam"]
//  }
//}
//
//resource_group = "alb"
