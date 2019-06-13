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


resource "aws_route53_zone" "root" {
  name = "${var.root_domain_name}."
}

resource "aws_route53_zone" "subdomain" {
  name = "${var.subdomain}.${var.root_domain_name}."
}

resource "aws_route53_record" "subdomain_root_records" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name = "${var.subdomain}.${var.root_domain_name}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.root.name_servers.0}",
    "${aws_route53_zone.root.name_servers.1}",
    "${aws_route53_zone.root.name_servers.2}",
    "${aws_route53_zone.root.name_servers.3}",
  ]
}

//                                                    Cert

resource "aws_acm_certificate" "certificate" {
//  domain_name = ".${var.root_domain_name}"
  domain_name = "${var.subdomain}.${var.root_domain_name}"
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.subdomain}.${var.root_domain_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn = "${aws_acm_certificate.certificate.arn}"
  validation_record_fqdns = [
    "${aws_route53_record.cert_validation.fqdn}",
  ]
}

resource "aws_route53_record" "cert_validation" {
  name = "${aws_acm_certificate.certificate.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.certificate.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.root.zone_id}"
  records = [
    "${aws_acm_certificate.certificate.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}
