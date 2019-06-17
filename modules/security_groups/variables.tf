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

variable "corporate_ip" {
  description = "The ip you are going to ssh from"
}
