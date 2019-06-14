terragrunt = {
  terraform {
    source = "../../../modules//logs"
  }

  include {
    path = "${find_in_parent_folders()}"
  }

//  dependencies {
//    paths = [
//      "../vpc",
//      "../security_groups",
//      "../iam"]
//  }
}

resource_group = "logs"
lb_logs_path = "lb-logs"
s3_logs_path = "s3-logs"
log_bucket_region = "us-east-1"