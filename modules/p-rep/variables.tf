

variable "region" {}
variable "environment" {}
variable "resource_group" {}

variable "terraform_state_region" {}

variable "tags" {
  type = "map"
}


variable "private_subnets" {
  type = "list"
}

variable "instance_type" {}
variable "volume_size" {}
