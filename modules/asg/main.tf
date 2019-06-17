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

data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "dns", "terraform.tfstate"))}"
    region = "${var.terraform_state_region}"
  }
}

data "terraform_remote_state" "logs" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "logs", "terraform.tfstate"))}"
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

//data "aws_ami" "amazon-linux-2" {
//  most_recent = true
//  owners = ["amazon"]
//
//  filter {
//    name   = "owner-alias"
//    values = ["amazon"]
//  }
//
//  filter {
//    name   = "name"
//    values = ["amzn2-ami-hvm*"]
//}
//}

//resource "template_file" "user_data" {
//  template = "${file("${path.module}/data/user_data.sh")}"
//  vars {
//    region = "${var.region}"
//  }
//}

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

resource "aws_launch_configuration" "this" {
  name          = "web_config"
  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  user_data = "${file("${path.module}/data/user_data_ubuntu.sh")}"
  key_name = "${data.terraform_remote_state.keys.key_name}"
  security_groups = ["${data.terraform_remote_state.security_groups.security_group_ids}"]

  associate_public_ip_address = true

  ebs_block_device = {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "${var.volume_size}"
      delete_on_termination = true
  }
}

resource "aws_autoscaling_group" "this" {
  name = "${local.name}"
  vpc_zone_identifier = ["${data.terraform_remote_state.vpc.public_subnets}"]

  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_configuration = "${aws_launch_configuration.this.id}"

  target_group_arns = ["${aws_lb_target_group.grpc.arn}", "${aws_lb_target_group.rest.arn}"]
}


//                                                      Load Balancer

resource "aws_lb" "this" {
  load_balancer_type               = "application"
  name                             = "${local.name}"
  internal                         = false
  security_groups                  = ["${data.terraform_remote_state.security_groups.security_group_ids}"]
  subnets                          = ["${data.terraform_remote_state.vpc.public_subnets}"]
  idle_timeout                     = 60
  enable_http2                     = true

  ip_address_type                  = "ipv4"

  tags                             = "${merge(var.tags, map("Name", local.name))}"

  access_logs {
    enabled = true
    bucket  = "${data.terraform_remote_state.logs.log_bucket}"
//    This be a little weird but one is dynamic ^^ and one is not?
    prefix  = "${var.log_location_prefix}"
  }

  timeouts {
    create = "${var.load_balancer_create_timeout}"
    delete = "${var.load_balancer_delete_timeout}"
    update = "${var.load_balancer_update_timeout}"
  }
}

resource "aws_lb_target_group" "rest" {
  name                 = "${local.name}-rest"
  vpc_id               = "${data.terraform_remote_state.vpc.vpc_id}"
  port                 = "${var.rest_listener_port}"
  protocol             = "HTTPS"

  target_type          = ""
// TODO: Autoscaledawtf....
  health_check {
    interval            = ""
    path                = ""
    port                = ""
    healthy_threshold   = ""
    unhealthy_threshold = ""
    timeout             = ""
    protocol            = ""
    matcher             = ""
  }

  tags       = "${merge(var.tags, map("Name", join("-", list(local.name, "rest"))))}"

  depends_on = ["aws_lb.this"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "grpc" {
  name                 = "${local.name}-grpc"
  vpc_id               = "${data.terraform_remote_state.vpc.vpc_id}"
  port                 = "${var.grpc_listener_port}"
  protocol             = "HTTPS"

  target_type          = ""

  tags       = "${merge(var.tags, map("Name", join("-", list(local.name, "grpc"))))}"

  depends_on = ["aws_lb.this"]

  lifecycle {
    create_before_destroy = true
  }
}

//                                                Listener

resource "aws_lb_listener" "rest" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "${var.rest_listener_port}"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.terraform_remote_state.dns.cert_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.rest.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "grpc" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "${var.grpc_listener_port}"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.terraform_remote_state.dns.cert_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.grpc.arn}"
    type             = "forward"
  }
}

//                                                Target Group

resource "aws_alb_target_group" "rest" {
  name     = "${local.name}-rest"
  port     = "${var.rest_listener_port}"
  protocol = "HTTPS"
  vpc_id   = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_alb_target_group" "grpc" {
  name     = "${local.name}-gprc"
  port     = "${var.grpc_listener_port}"
  protocol = "HTTPS"
  vpc_id   = "${data.terraform_remote_state.vpc.vpc_id}"
}

//                                                Listener Rule

resource "aws_alb_listener_rule" "rest" {
  listener_arn = "${aws_lb_listener.rest.arn}"
  priority     = 99

  action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.rest.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.tracker_subdomain}.${var.root_domain_name}"]
//    TODO: Validate ^^
  }
}

resource "aws_alb_listener_rule" "grpc" {
  listener_arn = "${aws_lb_listener.grpc.arn}"
  priority     = 99

  action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.grpc.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.node_subdomain}.${var.root_domain_name}"]
//    TODO: Validate ^^
  }
}

//                                                Certificate

resource "aws_lb_listener_certificate" "grpc" {
  listener_arn    = "${aws_lb_listener.grpc.arn}"
  certificate_arn   = "${data.terraform_remote_state.dns.cert_arn}"
}

resource "aws_lb_listener_certificate" "rest" {
  listener_arn    = "${aws_lb_listener.rest.arn}"
  certificate_arn   = "${data.terraform_remote_state.dns.cert_arn}"
}
