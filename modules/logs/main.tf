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
  log_bucket = "${var.log_bucket == "" ? join("-", list(local.name, data.aws_caller_identity.this.account_id)) : var.log_bucket}"
  log_bucket_region = "${var.log_bucket_region == "" ? "us-east-1" : var.log_bucket_region}"
  log_location_prefix = "${var.log_location_prefix == "" ? "/logs" : var.log_location_prefix}"
}

resource "aws_s3_bucket" "this" {
  bucket        = "${local.log_bucket}"
  region        = "${local.log_bucket_region}"
  force_destroy = true
  //  TODO: FIX ^^ in prod
//  Will also need to expose these logs over endpoint presumably
}

resource "aws_s3_bucket_policy" "this" {
  bucket = "${aws_s3_bucket.this.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "*"
        ]
      },
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.this.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.this.bucket}/*"
      ]
    }
  ]
}
POLICY
}

//resource "aws_cloudwatch_log_group" "this_dmesg" {
//  name              = "/var/log/dmesg"
//  retention_in_days = 30
//}
//
//resource "aws_cloudwatch_log_group" "this_docker" {
//  name              = "/var/log/docker"
//  retention_in_days = 30
//}
//
//resource "aws_cloudwatch_log_group" "this_messages" {
//  name              = "/var/log/messages"
//  retention_in_days = 30
//}
