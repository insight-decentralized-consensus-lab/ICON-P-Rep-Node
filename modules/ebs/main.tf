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

resource "aws_ebs_volume" "this" {
  availability_zone = "${var.azs[0]}"
  size              = "${var.ebs_volume_size}"
  type = "gp2"
  tags = "${merge(local.tags, map("Name", "ebs-main"))}"

  lifecycle {
      prevent_destroy = "true"
  }
}
