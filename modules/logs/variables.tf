

variable "region" {}
variable "environment" {}
variable "resource_group" {}

variable "tags" {
  type = "map"
}


variable "private_subnets" {
  type = "list"
}

variable "terraform_state_region" {
  description = "AWS region used for Terraform states"
}

variable "lb_logs_path" {
  type = "string"
}

variable "s3_logs_path" {
  type = "string"
}


variable "log_bucket_region" {}
