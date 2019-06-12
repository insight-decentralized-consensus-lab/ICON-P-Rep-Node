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

//data "terraform_remote_state" "vpc" {
//  backend = "s3"
//  config = {
//    bucket = "${var.terraform_state_bucket}"
//    key = "${join("/", list(var.region, "vpc", "terraform.tfstate"))}"
//    region = "${var.terraform_state_region}"
//  }
//}
//
//data "terraform_remote_state" "security_groups" {
//  backend = "s3"
//  config = {
//    bucket = "${var.terraform_state_bucket}"
//    key = "${join("/", list(var.region, "security-groups", "terraform.tfstate"))}"
//    region = "${var.terraform_state_region}"
//  }
//}
//
//data "aws_ami" "amazon-linux-2" {
// most_recent = true
//
// filter {
//   name   = "owner-alias"
//   values = ["amazon"]
// }
//
// filter {
//   name   = "name"
//   values = ["amzn2-ami-hvm*"]
// }
//}
//
//resource "template_file" "user_data" {
//  count    = "${length(var.private_subnets)}"
//  template = "${file("${path.module}/data/user_data.sh")}"
//  vars {
//    region = "${var.region}"
//  }
//}

//resource "null_resource" "gen_key_pair" {
//  provisioner "local-exec" {
////    TODO
//    command = <<EOT
//      ssh-keygen -o
//    EOT
//  }
//}
//
//resource "aws_key_pair" "this" {
//  key_name = "${var.resource_group}"
//  public_key = "${file("${path.module}/data")}"
//
//  depends_on = ["null_resource.gen_key_pair"]
//}
//
//data "external" "ssh_key_generator" {
//  program = ["bash", "${path.root}/data/ssh_keygen.sh"]
//
//  query = {
//    cwd = "${path.cwd}"
//    environment = "${var.environment}"
//  }
//}
//
//
//resource "aws_key_pair" "admin" {
//  key_name   = "icon-${var.environment}-${data.aws_caller_identity.this.account_id}"
//  public_key = "${data.external.ssh_key_generator.result.public_key}"
//  depends_on = ["data.external.ssh_key_generator"]
//}

//resource "null_resource" "generate-sshkey" {
//    provisioner "local-exec" {
//        command = "yes y | ssh-keygen -b 4096 -t rsa -C 'terraform-testing' -N '' -f id_rsa "
//    }
//}

//resource "null_resource" "ssh-keygen-delete" {
//    provisioner "local-exec" {
//        command = "ssh-keygen -R id_rsa}"
//    }
//}


resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "key_priv" {
  content  = "${tls_private_key.key.private_key_pem}"
  filename = "${path.cwd}/id_rsa"
}

resource "null_resource" "key_chown" {
  provisioner "local-exec" {
    command = "chmod 400 {path.cwd}/id_rsa"
  }

  depends_on = ["local_file.key_priv"]
}

resource "null_resource" "key_gen" {
  provisioner "local-exec" {
    command = "rm -f {path.cwd}/id_rsa.pub && ssh-keygen -y -f {path.cwd}/id_rsa > {path.cwd}/id_rsa.pub"
  }

  depends_on = ["local_file.key_priv"]
}

data "local_file" "key_pub" {
  filename = "${path.cwd}/id_rsa.pub"

  depends_on = ["null_resource.key_gen"]
}

resource "aws_key_pair" "key_tf" {
  public_key = "${data.local_file.key_pub.content}"
}

//module "asg" {
//  source  = "terraform-aws-modules/autoscaling/aws"
//  version = "~> 3.0"
//
//  name = "service"
//
//  # Launch configuration
//  lc_name = "example-lc"
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
//  asg_name                  = ""
//  vpc_zone_identifier       = "${data.terraform_remote_state.vpc.private_subnets}"
//  health_check_type         = "EC2"
//  min_size                  = 0
//  max_size                  = 1
//  desired_capacity          = 1
//  wait_for_capacity_timeout = 0
//
//  tags_as_map = "${var.tags}"
//}
