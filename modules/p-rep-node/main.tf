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
    bucket = "${var.terraform_state_bucket}"
    key = "${join("/", list(var.region, "vpc", "terraform.tfstate"))}"
    region = "${var.terraform_state_region}"
  }
}

data "terraform_remote_state" "security_groups" {
  backend = "s3"
  config = {
    bucket = "${var.terraform_state_bucket}"
    key = "${join("/", list(var.region, "security-groups", "terraform.tfstate"))}"
    region = "${var.terraform_state_region}"
  }
}

data "aws_ami" "amazon-linux-2" {
 most_recent = true

 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "template_file" "user_data" {
  count    = "${length(var.private_subnets)}"
  template = "${file("${path.module}/data/user_data.sh")}"
  vars {
    region             = "${var.region}"
  }
}

resource "null_resource" "gen_key_pair" {
  provisioner "local-exec" {
//    TODO
    command = <<EOT
      ssh-keygen -o
    EOT
  }
}

resource "aws_key_pair" "this" {
  key_name = "${var.resource_group}"
  public_key = "${file("${path.module}/data")}"

  depends_on = ["null_resource.gen_key_pair"]
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "service"

  # Launch configuration
  lc_name = "example-lc"

  image_id        = "${data.aws_ami.amazon-linux-2.image_id}"
  instance_type   = "${var.instance_type}"
  security_groups = "${list(data.terraform_remote_state.security_groups.security_group_id)}"

  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "${var.volume_size}"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    //      TODO FIX THIS LATER
    {
      volume_size = "50"
      volume_type = "gp2"
      delete_on_termination = true
    },
  ]

  # Auto scaling group
  asg_name                  = ""
  vpc_zone_identifier       = "${data.terraform_remote_state.vpc.private_subnets}"
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags_as_map = "${var.tags}"
}
