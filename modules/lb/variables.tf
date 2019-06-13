

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

variable "grpc_listener_port" {}
variable "rest_listener_port" {}

variable "rest_target_group_sticky" {}
variable "rest_target_group_path" {}
variable "rest_target_group_port" {}
variable "rest_port" {}
