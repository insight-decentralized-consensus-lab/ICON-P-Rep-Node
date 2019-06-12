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

data "terraform_remote_state" "keys" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "keys", "terraform.tfstate"))}"
    region = "${var.terraform_state_region}"
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]

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
  template = "${file("${path.module}/data/user_data.sh")}"
  vars {
    region = "${var.region}"
  }
}


//module "asg" {
//  source  = "terraform-aws-modules/autoscaling/aws"
//  version = "~> v2.0"
//
//  name = "service"
//
//  # Launch configuration
//  lc_name = "${local.name}"
//
//  image_id        = "${data.aws_ami.amazon-linux-2.image_id}"
//  instance_type   = "${var.instance_type}"
//  security_groups = "${list(data.terraform_remote_state.security_groups.security_group_id)}"
//
//  ebs_block_device = [
//    {
//      device_name           = "/dev/xvdz"
//      volume_type           = "gp2"
//      volume_size           = "${var.volume_size}"
//      delete_on_termination = true
//    },
//  ]
//
//  root_block_device = [
//    //      TODO FIX THIS LATER
//    {
//      volume_size = "50"
//      volume_type = "gp2"
//      delete_on_termination = true
//    },
//  ]
//
//  # Auto scaling group
//  asg_name                  = "${local.name}"
//  vpc_zone_identifier       = "${data.terraform_remote_state.vpc.private_subnets}"
//  health_check_type         = "EC2"
//  min_size                  = 0
//  max_size                  = 1
//  desired_capacity          = 1
//  wait_for_capacity_timeout = 0
//
//  tags_as_map = "${var.tags}"
//}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 2.0"

  name = "service"

  # Launch configuration
  lc_name = "example-lc"

//  image_id        = "ami-ebd02392"
//  instance_type   = "t2.micro"
//  security_groups = ["sg-12345678"]

  image_id        = "${data.aws_ami.amazon-linux-2.image_id}"
  instance_type   = "${var.instance_type}"
  security_groups = "${list(data.terraform_remote_state.security_groups.security_group_id)}"

  user_data = "${template_file.user_data.rendered}"
  key_name = "${data.terraform_remote_state.keys.key_name}"

  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "${var.volume_size}"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    {
      volume_size = "50"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "${local.name}"
  vpc_zone_identifier       = "${data.terraform_remote_state.vpc.private_subnets}"
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags_as_map = "${var.tags}"
}
