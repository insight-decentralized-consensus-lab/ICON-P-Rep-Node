data "aws_caller_identity" "this" {}


locals {
  common_tags = "${map(
    "Terraform", true,
    "Environment", "${var.environment}"
  )}"
  tags = "${merge(var.tags, local.common_tags)}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "${var.terraform_state_bucket}"
    key = "${join("/", list(var.region, "vpc", "terraform.tfstate"))}"
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

resource "template_file" "master_user_data" {
  count    = "${length(var.private_subnets) > 0 ? length(var.private_subnets) : 0}"
  template = "${file("${path.module}/data/masters_user_data.sh")}"

  vars {
    cluster_id         = ""
    region             = ""
    kubernetes_version = ""
  }
}


resource "aws_key_pair" "this" {
  key_name = "${var.resource_group}"
  public_key = "${file("${path.module}/data")}"
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "service"

  # Launch configuration
  lc_name = "example-lc"

  image_id        = "ami-ebd02392"
  instance_type   = "t2.micro"
  security_groups = ["sg-12345678"]

  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "50"
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
  asg_name                  = "example-asg"
  vpc_zone_identifier       = "${data.terraform_remote_state.vpc.private_subnets}"
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags_as_map = "${var.tags}"
}
