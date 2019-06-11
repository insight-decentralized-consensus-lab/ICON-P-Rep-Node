output "read_role_arn" {
  value = "${aws_iam_role.read.arn}"
}

output "read_role_name" {
  value = "${aws_iam_role.read.name}"
}

output "write_role_arn" {
  value = "${aws_iam_role.write.arn}"
}

output "write_role_name" {
  value = "${aws_iam_role.write.name}"
}

output "destroy_role_arn" {
  value = "${aws_iam_role.destroy.arn}"
}

output "destroy_role_name" {
  value = "${aws_iam_role.destroy.name}"
}
