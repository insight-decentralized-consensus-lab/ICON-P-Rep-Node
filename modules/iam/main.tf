data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

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

resource "aws_iam_role" "read" {
  name = "${local.name}-read"
  assume_role_policy = "${file("${path.module}/data/assume_role_policy.json")}"
}

resource "aws_iam_role" "write" {
  name = "${local.name}-write"
  assume_role_policy = "${file("${path.module}/data/assume_role_policy.json")}"
}

resource "aws_iam_role" "destroy" {
  name = "${local.name}-destroy"
  assume_role_policy = "${file("${path.module}/data/assume_role_policy.json")}"
}

resource "aws_iam_role" "audit" {
  name = "${local.name}-audit"
  assume_role_policy = "${file("${path.module}/data/assume_role_policy.json")}"
}

resource "template_file" "read" {
  template = "${file("${path.module}/data/read_policy.json")}"
  vars {
    terraform_state_bucket = "${local.terraform_state_bucket}"
  }
}

resource "template_file" "write" {
  template = "${file("${path.module}/data/write_policy.json")}"
  vars {
    terraform_state_bucket = "${local.terraform_state_bucket}"
  }
}

resource "template_file" "destroy" {
  template = "${file("${path.module}/data/destroy_policy.json")}"
  vars {
    terraform_state_bucket = "${local.terraform_state_bucket}"
  }
}

resource "template_file" "audit" {
  template = "${file("${path.module}/data/audit_policy.json")}"
  vars {
    terraform_state_bucket = "${local.terraform_state_bucket}"
  }
}

resource "aws_iam_role_policy" "read" {
  name   = "${local.name}-read"
  role   = "${aws_iam_role.read.name}"
  policy = "${template_file.read.rendered}"
}

resource "aws_iam_role_policy" "write" {
  name   = "${local.name}-write"
  role   = "${aws_iam_role.write.name}"
  policy = "${template_file.write.rendered}"
}

resource "aws_iam_role_policy" "destroy" {
  name   = "${local.name}-destroy"
  role   = "${aws_iam_role.destroy.name}"
  policy = "${template_file.destroy.rendered}"
}

resource "aws_iam_role_policy" "audit" {
  name   = "${local.name}-audit"
  role   = "${aws_iam_role.audit.name}"
  policy = "${template_file.audit.rendered}"
}



