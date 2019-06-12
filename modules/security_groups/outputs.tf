output "security_group_ids" {
  value = "${list(aws_security_group.rest.id, aws_security_group.grpc.id)}"
}
