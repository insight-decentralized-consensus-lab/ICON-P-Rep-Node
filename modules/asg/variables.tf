variable "region" {}
variable "environment" {}
variable "resource_group" {}

variable "tags" {
  type = "map"
}

variable "private_subnets" {
  type = "list"
}

variable "instance_type" {}
variable "volume_size" {}

variable "terraform_state_region" {
  description = "AWS region used for Terraform states"
}

variable "grpc_listener_port" {}
variable "grpc_target_group_sticky" {}
variable "grpc_target_group_path" {}
variable "grpc_target_group_port" {}

variable "rest_listener_port" {}
variable "rest_target_group_sticky" {}
variable "rest_target_group_path" {}
variable "rest_target_group_port" {}

variable "log_bucket" {}
variable "log_bucket_region" {}
variable "log_location_prefix" {}

variable "load_balancer_create_timeout" {
  default = "10m"
}
variable "load_balancer_delete_timeout" {
  default = "10m"
}
variable "load_balancer_update_timeout" {
  default = "10m"
}

variable "root_domain_name" {}

variable "icon_domain_name" {}
variable "node_subdomain" {}
variable "tracker_subdomain" {}
