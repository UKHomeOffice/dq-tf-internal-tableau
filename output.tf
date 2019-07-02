output "iam_roles" {
  value = [
    "${aws_iam_role.int_tableau.id}",
    "${aws_iam_role.postgres.id}",
  ]
}

output "rds_internal_tableau_endpoint" {
  value = "${aws_db_instance.internal_reporting.endpoint}"
}

output "rds_internal_tableau_address" {
  value = "${aws_db_instance.internal_reporting.address}"
}
