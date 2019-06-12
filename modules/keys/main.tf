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

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "key_priv" {
  content  = "${tls_private_key.key.private_key_pem}"
  filename = "${path.module}/id_rsa"
}


resource "null_resource" "key_chown" {
  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/id_rsa"
  }

  triggers {
    always_run = "${timestamp()}"
  }
  depends_on = ["local_file.key_priv"]
}

// TODO: This needs to have some logic to import existing keys and export to anywhere
resource "null_resource" "key_gen" {
  provisioner "local-exec" {
    command = "ssh-keygen -y -f ${path.module}/id_rsa > ${path.module}/id_rsa.pub"
  }

  triggers {
    always_run = "${timestamp()}"
  }
  depends_on = ["local_file.key_priv"]
}

data "local_file" "key_pub" {
  filename = "${path.module}/id_rsa.pub"

  depends_on = ["null_resource.key_gen"]
}

resource "aws_key_pair" "key" {
  key_name = "${local.name}"
  public_key = "${data.local_file.key_pub.content}"
}
