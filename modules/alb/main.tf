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

data "terraform_remote_state" "asg" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "asg", "terraform.tfstate"))}"
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

data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = "${local.terraform_state_bucket}"
    key = "${join("/", list(var.region, "dns", "terraform.tfstate"))}"
    region = "${var.terraform_state_region}"
  }
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
  port                 = 9000
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

  tags       = "${merge(var.tags, map("Name", join("-", local.name, "rest")))}"

  depends_on = ["aws_lb.this"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "grpc" {
  name                 = "${local.name}-grpc"
  vpc_id               = "${data.terraform_remote_state.vpc.vpc_id}"
  port                 = 7100
  protocol             = "HTTPS"

  target_type          = ""

  tags       = "${merge(var.tags, map("Name", join("-", local.name, "grpc")))}"

  depends_on = ["aws_lb.this"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "rest" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = 9000
  protocol          = "HTTPS"
  certificate_arn   = "${data.terraform_remote_state.dns.cert_arn}"
  ssl_policy        = ""

  default_action {
    target_group_arn = "${aws_lb_target_group.rest.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "grpc" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = 7100
  protocol          = "HTTPS"
  certificate_arn   = "${data.terraform_remote_state.dns.cert_arn}"
  ssl_policy        = ""

  default_action {
    target_group_arn = "${aws_lb_target_group.grpc.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "https_listener" {
  listener_arn    = "${aws_lb_listener.grpc.arn}"
  certificate_arn   = "${data.terraform_remote_state.dns.cert_arn}"
}
