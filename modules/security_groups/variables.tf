variable "region" {
  type = "string"
}
variable "environment" {
  type = "string"
}

variable "tags" {
  type = "map"
}

variable "terraform_state_region" {
  description = "AWS region used for Terraform states"
}