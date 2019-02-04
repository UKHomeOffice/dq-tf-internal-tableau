output "iam_roles" {
  value = ["${aws_iam_role.int_tableau.id}"]
}

output "rds_internal_tableau_endpoint" {
  value = "${aws_db_instance.postgres.endpoint}"
}
