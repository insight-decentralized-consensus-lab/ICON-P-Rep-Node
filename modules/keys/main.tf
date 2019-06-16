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
// TODO: This needs to have some logic to import existing keys and export to anywhere. Right now we just do both and
//then import when whatever is left.
resource "tls_private_key" "key" {
//  count = "${var.local_key_file == "" ? 0 : 1}"

  algorithm = "RSA"
}

resource "local_file" "key_priv" {
//  count = "${var.local_key_file == "" ? 0 : 1}"

  content  = "${tls_private_key.key.private_key_pem}"
  filename = "${path.module}/id_rsa"
}


resource "null_resource" "key_chown" {
//  count = "${var.local_key_file == "" ? 0 : 1}"

  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/id_rsa"
  }

  triggers {
    always_run = "${timestamp()}"
  }
  depends_on = ["local_file.key_priv"]
}


resource "null_resource" "key_gen" {
//  count = "${var.local_key_file == "" ? 0 : 1}"

  provisioner "local-exec" {
    command = "ssh-keygen -y -f ${path.module}/id_rsa > ${path.module}/id_rsa.pub"
  }

  triggers {
    always_run = "${timestamp()}"
  }
  depends_on = ["local_file.key_priv"]
}

data "local_file" "key_gen" {
//  count = "${var.local_key_file == "" ? 0 : 1}"
  filename = "${path.module}/id_rsa.pub"

  depends_on = ["null_resource.key_gen"]
}

data "local_file" "key_local" {
  count = "${var.local_key_file == "" ? 0 : 1}"
  filename = "${var.local_key_file}"
}

resource "aws_key_pair" "key" {
  key_name = "${local.name}"
  public_key = "${var.local_key_file == "" ? data.local_file.key_local.content : data.local_file.key_local.content}"
}
