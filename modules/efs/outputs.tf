output "file_system_id" {
  value = "${aws_efs_file_system.this.id}"
}

//output "mount_path" {
//  value = "${aws_efs_mount_target.icon-data.*.id}"
//}