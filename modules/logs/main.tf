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

resource "aws_s3_bucket" "logs" {
  bucket = "lb-logs-${data.aws_caller_identity.this.account_id}"
}

data "aws_iam_policy_document" "logs_bucket_policy" {

  statement {
    sid       = "Allow LB to write logs"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.logs.bucket}/${var.lb_logs_path}*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:lb"]
    }
  }

  statement {
    sid       = "Permit access log delivery by AWS ID for Log Delivery service"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.logs.bucket}/${var.s3_logs_path}*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:audit"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = "${aws_s3_bucket.logs.bucket}"
  policy = "${data.aws_iam_policy_document.logs_bucket_policy.json}"
}