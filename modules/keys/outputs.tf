output "key_name" {
  value = "${aws_key_pair.key.key_name}"
}

output "public_key" {
  value = "${var.local_public_key == "" ? aws_key_pair.key.public_key : data.local_file.key_local.content}"
}