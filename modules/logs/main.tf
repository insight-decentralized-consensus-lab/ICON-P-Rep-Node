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

resource "aws_s3_bucket" "this" {
  bucket        = "${local.name}-${data.aws_caller_identity.this.account_id}"
  region        = "${var.log_bucket_region}"
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
