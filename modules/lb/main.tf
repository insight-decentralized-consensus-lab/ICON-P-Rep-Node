data "aws_caller_identity" "this" {}

locals {
  name = "${var.resource_group}"
  common_tags = "${map(
    "Terraform", true,
    "Environment", "${var.environment}"
  )}"
  tags = "${merge(var.tags, local.common_tags)}"
  terraform_state_bucket = "terraform-states-${data.aws_caller_identity.this.account_id}"
  terraform_state_region = "${var.terraform_state_region}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "vpc", "terraform.tfstate"))}"
    region = "${var.terraform_state_region}"
  }
}

data "terraform_remote_state" "security_groups" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "security-groups", "terraform.tfstate"))}"
    region = "${var.terraform_state_region}"
  }
}

resource "aws_elb" "this" {
  name            = "${local.name}"
  subnets         = ["${data.terraform_remote_state.vpc.public_subnets}"]

  security_groups = ["${var.security_groups}"]

  cross_zone_load_balancing   = "${var.cross_zone_load_balancing}"
  idle_timeout                = "${var.idle_timeout}"
  connection_draining         = "${var.connection_draining}"
  connection_draining_timeout = "${var.connection_draining_timeout}"

  listener     = ["${var.listener}"]
  access_logs  = ["${var.access_logs}"]
  health_check = ["${var.health_check}"]

  tags = "${merge(var.tags, map("Name", format("%s", var.name)))}"
}