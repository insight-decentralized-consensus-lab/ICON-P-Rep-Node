
variable "region" {
  type = "string"
}
variable "environment" {
  type = "string"
}

variable "tags" {
  type = "map"
}

variable "resource_group" {
  type = "string"
}

variable "terraform_state_region" {
  description = "AWS region used for Terraform states"
}