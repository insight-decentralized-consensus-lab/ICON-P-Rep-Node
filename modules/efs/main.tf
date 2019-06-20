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
    region = "${local.terraform_state_region}"
  }
}

resource "aws_efs_file_system" "this" {
  performance_mode = "generalPurpose" # or maxIO
//  performance_mode = "${var.performance_mode}"
  encrypted        = false
//  kms_key_id       = "${var.kms_key_id}"
  tags             = "${local.tags}"
}

resource "aws_efs_mount_target" "icon-data" {
//  This is out of the question for public subnets
  count = "${length(var.private_subnets)}"
  file_system_id  = "${aws_efs_file_system.this.id}"
  subnet_id       = "${element(compact(data.terraform_remote_state.vpc.private_subnets), count.index)}"
  security_groups = ["${aws_security_group.efs.id}"]
}

resource "aws_security_group" "efs" {
  name = "efs"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  description = "Security group for EFS on p rep nodes"

  tags = "${local.tags}"
}

resource "aws_security_group_rule" "efs_ingress" {
  type = "ingress"
  security_group_id = "${aws_security_group.efs.id}"

  source_security_group_id = "${aws_security_group.efs.id}"
//  ^^ Cannot be specified with cidr_blocks
//  cidr_blocks = ["${var.cidr}"]
  from_port = 2049
  to_port = 2049
  protocol = "tcp"
}

resource "aws_security_group_rule" "efs_egress" {
  type = "egress"
  security_group_id = "${aws_security_group.efs.id}"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
