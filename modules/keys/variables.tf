

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