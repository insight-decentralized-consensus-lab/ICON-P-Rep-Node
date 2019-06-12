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

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "key_priv" {
  content  = "${tls_private_key.key.private_key_pem}"
  filename = "${path.module}/id_rsa"
}


resource "null_resource" "key_chown" {
  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/id_rsa"
  }

  triggers {
    always_run = "${timestamp()}"
  }
  depends_on = ["local_file.key_priv"]
}

resource "null_resource" "key_gen" {
  provisioner "local-exec" {
    command = "ssh-keygen -y -f ${path.module}/id_rsa > ${path.module}/id_rsa.pub"
  }

  triggers {
    always_run = "${timestamp()}"
  }
  depends_on = ["local_file.key_priv"]
}

data "local_file" "key_pub" {
  filename = "${path.module}/id_rsa.pub"

  depends_on = ["null_resource.key_gen"]
}

resource "aws_key_pair" "key_tf" {
  key_name = "${local.name}"
  public_key = "${data.local_file.key_pub.content}"
}
//
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
  key_name = "${aws_key_pair.key_tf.key_name}"

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

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "megasecret"
      propagate_at_launch = true
    },
  ]

  tags_as_map = "${var.tags}"
}
