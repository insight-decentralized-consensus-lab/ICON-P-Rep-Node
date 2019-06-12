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

//resource "aws_lb" "this" {
//  name               = "${local.name}"
//  load_balancer_type = "network"
//
////  TODO: THis can be made dynamic with HCL2 - https://stackoverflow.com/questions/49284508/dynamic-subnet-mappings-for-aws-lb
//  subnet_mapping {
//    subnet_id     = "${data.terraform_remote_state.vpc.subnet_ids[0]}"
//    allocation_id = "${aws_eip.example1.id}"
//  }
//
//  subnet_mapping {
//    subnet_id     = "${aws_subnet.example2.id}"
//    allocation_id = "${aws_eip.example2.id}"
//  }
//}
//resource "aws_lb_listener" "rest" {
//    load_balancer_arn = "${aws_lb.this.arn}"
//    port              = 8500
//    protocol          = "TCP"
//
//    default_action {
//        target_group_arn = "${aws_lb_target_group.consul.arn}"
//        type             = "forward"
//    }
//}

resource "aws_alb_target_group" "rest_target_group" {
  name     = "${local.name}"
  port     = "${var.rest_port}"
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.vpc_id}"
  tags {
    name = "rest-${local.name}-target-group"
  }
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = "${var.rest_target_group_sticky}"
  }
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "${var.rest_target_group_path}"
    port                = "${var.rest_target_group_port}"
  }
}

resource "aws_alb" "alb" {
  name            = "${local.name}"
  subnets         = "${}"
  security_groups = "${data.terraform_remote_state.security_groups.security_group_ids}"
  internal        = false

  access_logs {
    bucket = "${data.terraform_remote_state.logs.logs_bucket}"
    prefix = "lb-logs"
  }
}

resource "aws_alb_listener" "rest_listener" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "${var.rest_listener_port}"
  protocol          = "tcp"

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "grpc_listener" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "${var.grpc_listener_port}"
  protocol          = "tcp"

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target.arn}"
    type             = "forward"
  }
}


resource "aws_alb_listener_rule" "listener_rule" {
  depends_on   = ["aws_alb_target_group.alb_target_group"]
  listener_arn = "${aws_alb_listener.alb_listener.arn}"
  priority     = "${var.priority}"
  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.alb_target_group.id}"
  }
  condition {
    field  = "path-pattern"
    values = ["${var.alb_path}"]
  }
}



resource "aws_autoscaling_attachment" "svc_asg_external2" {
  alb_target_group_arn   = "${aws_alb_target_group.alb_target_group.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.svc_asg.id}"
}
