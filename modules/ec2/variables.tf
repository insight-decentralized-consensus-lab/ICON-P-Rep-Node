

variable "region" {}
variable "azs" {
  type = "list"
}
variable "environment" {}
variable "resource_group" {}

variable "tags" {
  type = "map"
}


variable "private_subnets" {
  type = "list"
}

variable "instance_type" {}

variable "terraform_state_region" {
  description = "AWS region used for Terraform states"
}

variable "root_volume_size" {}
variable "volume_path" {}

variable "local_private_key" {}

variable "efs_directory" {}
