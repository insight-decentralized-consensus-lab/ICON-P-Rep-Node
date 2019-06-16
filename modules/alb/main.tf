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

  target_groups_default_configs = {
    cookie_duration                  = 86400
    deregistration_delay             = 300
    health_check_interval            = 10
    health_check_healthy_threshold   = 3
    health_check_path                = "/"
    health_check_port                = "traffic-port"
    health_check_timeout             = 5
    health_check_unhealthy_threshold = 3
    health_check_matcher             = "200-299"
    stickiness_enabled               = true
    target_type                      = "instance"
    slow_start                       = 0
  }

  target_groups_defaults = "${merge(local.target_groups_default_configs, var.target_groups_defaults)}"
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


resource "aws_lb" "application" {
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

resource "aws_lb_target_group" "main" {
  name                 = "${lookup(var.target_groups[count.index], "name")}"
  vpc_id               = "${var.vpc_id}"
  port                 = "${lookup(var.target_groups[count.index], "backend_port")}"
  protocol             = "${upper(lookup(var.target_groups[count.index], "backend_protocol"))}"
  deregistration_delay = "${lookup(var.target_groups[count.index], "deregistration_delay", lookup(local.target_groups_defaults, "deregistration_delay"))}"
  target_type          = "${lookup(var.target_groups[count.index], "target_type", lookup(local.target_groups_defaults, "target_type"))}"
  slow_start           = "${lookup(var.target_groups[count.index], "slow_start", lookup(local.target_groups_defaults, "slow_start"))}"

  health_check {
    interval            = "${lookup(var.target_groups[count.index], "health_check_interval", lookup(local.target_groups_defaults, "health_check_interval"))}"
    path                = "${lookup(var.target_groups[count.index], "health_check_path", lookup(local.target_groups_defaults, "health_check_path"))}"
    port                = "${lookup(var.target_groups[count.index], "health_check_port", lookup(local.target_groups_defaults, "health_check_port"))}"
    healthy_threshold   = "${lookup(var.target_groups[count.index], "health_check_healthy_threshold", lookup(local.target_groups_defaults, "health_check_healthy_threshold"))}"
    unhealthy_threshold = "${lookup(var.target_groups[count.index], "health_check_unhealthy_threshold", lookup(local.target_groups_defaults, "health_check_unhealthy_threshold"))}"
    timeout             = "${lookup(var.target_groups[count.index], "health_check_timeout", lookup(local.target_groups_defaults, "health_check_timeout"))}"
    protocol            = "${upper(lookup(var.target_groups[count.index], "healthcheck_protocol", lookup(var.target_groups[count.index], "backend_protocol")))}"
    matcher             = "${lookup(var.target_groups[count.index], "health_check_matcher", lookup(local.target_groups_defaults, "health_check_matcher"))}"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = "${lookup(var.target_groups[count.index], "cookie_duration", lookup(local.target_groups_defaults, "cookie_duration"))}"
    enabled         = "${lookup(var.target_groups[count.index], "stickiness_enabled", lookup(local.target_groups_defaults, "stickiness_enabled"))}"
  }

  tags       = "${merge(var.tags, map("Name", lookup(var.target_groups[count.index], "name")))}"
  count      = "${var.create_alb && var.logging_enabled ? var.target_groups_count : 0}"
  depends_on = ["aws_lb.application"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "frontend_http_tcp" {
  load_balancer_arn = "${element(concat(aws_lb.application.*.arn, aws_lb.application_no_logs.*.arn), 0)}"
  port              = "${lookup(var.http_tcp_listeners[count.index], "port")}"
  protocol          = "${lookup(var.http_tcp_listeners[count.index], "protocol")}"
  count             = "${var.create_alb && var.logging_enabled ? var.http_tcp_listeners_count : 0}"

  default_action {
    target_group_arn = "${aws_lb_target_group.main.*.id[lookup(var.http_tcp_listeners[count.index], "target_group_index", 0)]}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = "${element(concat(aws_lb.application.*.arn, aws_lb.application_no_logs.*.arn), 0)}"
  port              = "${lookup(var.https_listeners[count.index], "port")}"
  protocol          = "HTTPS"
  certificate_arn   = "${lookup(var.https_listeners[count.index], "certificate_arn")}"
  ssl_policy        = "${lookup(var.https_listeners[count.index], "ssl_policy", var.listener_ssl_policy_default)}"
  count             = "${var.create_alb && var.logging_enabled ? var.https_listeners_count : 0}"

  default_action {
    target_group_arn = "${aws_lb_target_group.main.*.id[lookup(var.https_listeners[count.index], "target_group_index", 0)]}"
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "https_listener" {
  listener_arn    = "${aws_lb_listener.frontend_https.*.arn[lookup(var.extra_ssl_certs[count.index], "https_listener_index")]}"
  certificate_arn = "${lookup(var.extra_ssl_certs[count.index], "certificate_arn")}"
  count           = "${var.create_alb && var.logging_enabled ? var.extra_ssl_certs_count : 0}"
}