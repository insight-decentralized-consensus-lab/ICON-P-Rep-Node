data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

locals {
  common_tags = "${map(
    "Terraform", true,
    "Environment", "${var.environment}"
  )}"
  tags = "${merge(var.tags, local.common_tags)}"
  terraform_state_bucket = "terraform-states-${data.aws_caller_identity.this.account_id}"
//  TODO: This might mess things up when switching regions
  terraform_state_region = "${data.aws_region.this.name}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "vpc", "terraform.tfstate"))}"
    region = "${local.terraform_state_region}"
  }
}

resource "aws_security_group" "p-rep" {
  name = "p-rep-sg"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  description = "Security group for p rep nodes"

  tags = "${local.tags}"
}

resource "aws_security_group_rule" "p-rep-ingress-9000" {
  type = "ingress"
  security_group_id = "${aws_security_group.p-rep.id}"
  source_security_group_id = "${aws_security_group.p-rep.id}"
  from_port = 9000
  to_port = 9000
  protocol = "-1"
}

resource "aws_security_group_rule" "p-rep-ingress-7100" {
  type = "ingress"
  security_group_id = "${aws_security_group.p-rep.id}"
  source_security_group_id = "${aws_security_group.p-rep.id}"
  from_port = 7100
  to_port = 7100
  protocol = "-1"
}

resource "aws_security_group_rule" "p-rep-egress" {
  type = "egress"
  security_group_id = "${aws_security_group.p-rep.id}"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]
}