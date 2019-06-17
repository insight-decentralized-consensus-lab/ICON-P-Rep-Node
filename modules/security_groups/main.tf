data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

locals {
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

resource "aws_security_group" "rest" {
  name = "rest"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  description = "Security group for rest api on p rep nodes"

  tags = "${local.tags}"
}

resource "aws_security_group_rule" "rest_ingress" {
  type = "ingress"
  security_group_id = "${aws_security_group.rest.id}"
  cidr_blocks = ["0.0.0.0/0"]
  from_port = 9000
  to_port = 9000
  protocol = "tcp"
}

resource "aws_security_group_rule" "rest_egress" {
  type = "egress"
  security_group_id = "${aws_security_group.rest.id}"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "grpc" {
  name = "grpc"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  description = "Security group for grpc communication on p rep nodes"

  tags = "${local.tags}"
}

resource "aws_security_group_rule" "grpc_egress" {
  type = "egress"
  security_group_id = "${aws_security_group.grpc.id}"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "grpc_ingress" {
  type = "ingress"
  security_group_id = "${aws_security_group.grpc.id}"
  cidr_blocks = ["0.0.0.0/0"]
  from_port = 7100
  to_port = 7100
  protocol = "tcp"
}


resource "aws_security_group_rule" "ssh_ingress" {
  count = "${var.corporate_ip == "" ? 0 : 1}"

  type = "ingress"
  security_group_id = "${aws_security_group.grpc.id}"
  cidr_blocks = ["${var.corporate_ip}/32"]
  from_port = 22
  to_port = 22
  protocol = "tcp"
}

resource "aws_security_group_rule" "testing_ssh_ingress" {
  count = "${var.corporate_ip == "" ? 1 : 0}"

  type = "ingress"
  security_group_id = "${aws_security_group.grpc.id}"
  cidr_blocks = ["0.0.0.0/0"]
  from_port = 22
  to_port = 22
  protocol = "tcp"
}

//resource "aws_security_group" "p_rep" {
//  name = "p-rep-sg"
//  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
//  description = "Security group for p rep nodes"
//
//  tags = "${local.tags}"
//
//  ingress {
//    from_port = 9000
//    protocol = "tcp"
//    to_port = 9000
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  ingress {
//    from_port = 7100
//    protocol = "tcp"
//    to_port = 7100
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  egress {
//    from_port = 0
//    protocol = "tcp"
//    to_port = 0
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//}