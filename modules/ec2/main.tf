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
    key = "${join("/", list(var.region, "security_groups", "terraform.tfstate"))}"
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

data "terraform_remote_state" "ebs" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "ebs", "terraform.tfstate"))}"
    region = "${var.terraform_state_region}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_eip" "this" {
  vpc = true
  instance = "${aws_instance.this.id}"

  lifecycle {
      prevent_destroy = "true"
  }
}

//data "aws_ebs_volume" "this" {
//  volume_id = "${data.terraform_remote_state.ebs.id}"
//}

resource "aws_instance" "this" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  user_data = "${file("${path.module}/data/user_data_ubuntu.sh")}"
  key_name = "${data.terraform_remote_state.keys.key_name}"

  subnet_id = "${data.terraform_remote_state.vpc.public_subnets[0]}"

  security_groups = ["${data.terraform_remote_state.security_groups.security_group_ids}"]

  root_block_device = {
      volume_type           = "gp2"
      volume_size           = "${var.root_volume_size}"
      delete_on_termination = true
  }
//  ebs_block_device = {
//      device_name           = "/dev/xvdz"
//      volume_type           = "gp2"
//      volume_size           = "${var.ebs_volume_size}"
//      delete_on_termination = true
//  }
//  TODO: Consider ephemeral volumes and how they might need to be scaled behind load balancer
}

resource "aws_volume_attachment" "this" {
  device_name = "${var.volume_path}"
  volume_id   = "${data.terraform_remote_state.ebs.volume_id}"
//  volume_id = "${data.aws_ebs_volume.this.id}"
  instance_id = "${aws_instance.this.id}"

  provisioner "remote-exec" {
    script = "${file("${path.module}/data/attach-data-volume.sh")}"
    connection {
      host = "${aws_instance.this.public_ip}"
    }
  }

  provisioner "remote-exec" {
    script = "${file("${path.module}/data/run-icon-docker-compose.sh")}"
    connection {
      host = "${aws_instance.this.public_ip}"
    }
  }
} 

//resource "aws_ebs_volume" "this" {
//  availability_zone = "${var.azs[0]}"
//  size              = 100
//  type = "gp2"
//  tags = "${merge(local.tags, map("Name", "ebs-main"))}"
//
//  lifecycle {
//      prevent_destroy = "false"
//  }
//
//  count = 0
//}
