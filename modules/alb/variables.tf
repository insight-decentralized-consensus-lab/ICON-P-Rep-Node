

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

variable "target_groups_defaults" {
  description = "Default values for target groups as defined by the list of maps."
  type = "map"
  default     = {}
}


variable "target_groups" {
  description = "A list of maps containing key/value pairs that define the target groups to be created. Order of these maps is important and the index of these are to be referenced in listener definitions. Required key/values: name, backend_protocol, backend_port. Optional key/values are in the target_groups_defaults variable."
  type        = "list"
  default     = []
}

variable "target_groups_count" {
  description = "A manually provided count/length of the target_groups list of maps since the list cannot be computed."
  default     = 0
}