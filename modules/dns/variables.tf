

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


variable "root_domain_name" {}
variable "subdomain" {}
