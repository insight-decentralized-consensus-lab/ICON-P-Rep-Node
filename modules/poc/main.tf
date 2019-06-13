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

//module "cli" {
//  source = "github.com/matti/terraform-shell-resource.git?ref=v0.6.0"
//  command = "cookiecutter https://github.com/alexfu/cookiecutter-android -o ${path.module}/output --no-input"
//}

resource "null_resource" "key_chown" {
  provisioner "local-exec" {
//    command = "cookiecutter https://github.com/alexfu/cookiecutter-android -o ${path.module}/output --no-input"
    command = "cookiecutter https://github.com/alexfu/cookiecutter-android -o ${path.module}/output"
  }

  triggers {
    always_run = "${timestamp()}"
  }
}

// TODO: This needs to have some logic to import existing keys and export to anywhere