data "aws_caller_identity" "this" {}
data "aws_region" "current" {}

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

data "terraform_remote_state" "efs" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "efs", "terraform.tfstate"))}"
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
//  user_data = "${file("${path.module}/data/user_data_ubuntu.sh")}"
  user_data = "${data.template_file.user-data.rendered}"
//  user_data = "${data.template_file.cloud-init.rendered}"

  key_name = "${data.terraform_remote_state.keys.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.this.id}"
  subnet_id = "${data.terraform_remote_state.vpc.public_subnets[0]}"

  security_groups = ["${data.terraform_remote_state.security_groups.security_group_ids}"]

  root_block_device = {
      volume_type           = "gp2"
      volume_size           = "${var.root_volume_size}"
      delete_on_termination = true
  }
}

data "template_file" "cloud-init" {
  template = "${file("${path.module}/data/cloud_config_ubuntu_efs.yml")}"

  vars {
    efs_directory = "${var.efs_directory}"
    file_system_id = "${data.terraform_remote_state.efs.file_system_id}"
    ssh_public_key = "${data.terraform_remote_state.keys.public_key}"
  }
}

data "template_file" "user-data" {
  template = "${file("${path.module}/data/user_data_ubuntu_ebs.sh")}"
}

data "template_file" "volume" {
  template = "${file("${path.module}/data/attach-data-volume.sh")}"
}

data "template_file" "docker" {
  template = "${file("${path.module}/data/run-icon-docker-compose.sh")}"
}

resource "aws_volume_attachment" "this" {
  device_name = "${var.volume_path}"
  volume_id   = "${data.terraform_remote_state.ebs.volume_id}"
//  volume_id = "${data.aws_ebs_volume.this.id}"
  instance_id = "${aws_instance.this.id}"

  force_detach = true
}

//resource "null_resource" "volume" {
//  provisioner "remote-exec" {
//    inline = "${data.template_file.volume.rendered}"
////    script = "${file("${path.module}/data/attach-data-volume.sh")}"
//    connection {
//      user = "ubuntu"
//      private_key = "${file(var.local_private_key)}"
//      host = "${aws_eip.this.public_ip}"
//    }
//  }
//  depends_on = ["aws_instance.this"]
//}

//resource "null_resource" "docker" {
//  provisioner "remote-exec" {
//    inline = "${data.template_file.docker.rendered}"
////    script = "${file("${path.module}/data/run-icon-docker-compose.sh")}"
//    connection {
//      user = "ubuntu"
//      private_key = "${file(var.local_private_key)}"
//      host = "${aws_eip.this.public_ip}"
//    }
//  }
//  depends_on = ["aws_volume_attachment.this"]
//}

resource "aws_iam_instance_profile" "this" {
  name = "test_profile"
  role = "${aws_iam_role.this.name}"
}

data "template_file" "efs_mount_policy" {
  template = "${file("${path.module}/data/efs_mount_policy.json")}"
  vars {
    file_system_id = "${data.terraform_remote_state.efs.file_system_id}"
    account_id = "${data.aws_caller_identity.this.account_id}"
    region = "${data.aws_region.current.name}"
  }
}

data "template_file" "ebs_mount_policy" {
  template = "${file("${path.module}/data/ebs_mount_policy.json")}"
  vars {
    file_system_id = "${data.terraform_remote_state.efs.file_system_id}"
    account_id = "${data.aws_caller_identity.this.account_id}"
    region = "${data.aws_region.current.name}"
  }
}

resource "aws_iam_policy" "efs_mount_policy" {
  name = "${title(local.name)}EFSPolicy"
  policy = "${data.template_file.efs_mount_policy.rendered}"
}

resource "aws_iam_policy" "ebs_mount_policy" {
  name = "${title(local.name)}EBSPolicy"
  policy = "${data.template_file.ebs_mount_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "efs_mount_policy" {
  role       = "${aws_iam_role.this.name}"
  policy_arn = "${aws_iam_policy.ebs_mount_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "ebs_mount_policy" {
  role       = "${aws_iam_role.this.name}"
  policy_arn = "${aws_iam_policy.ebs_mount_policy.arn}"
}

resource "aws_iam_role" "this" {
  name = "${title(local.name)}EFSRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
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
