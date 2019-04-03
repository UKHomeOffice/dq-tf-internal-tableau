output "iam_roles" {
  value = [
    "${aws_iam_role.int_tableau.id}",
    "${aws_iam_role.postgres}",
  ]
}

output "rds_internal_tableau_endpoint" {
  value = "${aws_db_instance.postgres.endpoint}"
}

output "rds_internal_tableau_address" {
  value = "${aws_db_instance.postgres.address}"
}
