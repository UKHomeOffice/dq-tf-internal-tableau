output "iam_roles" {
  value = [
    "${aws_iam_role.int_tableau.id}",
    "${aws_iam_role.postgres.id}",
  ]
}

output "rds_internal_tableau_endpoint" {
  value = "${aws_db_instance.postgres.endpoint}"
}

output "rds_internal_tableau_address" {
  value = "${aws_db_instance.postgres.address}"
}

output "rds_internal_tableau_staging_endpoint" {
  value = [
    "${join("", aws_db_instance.internal_reporting_snapshot_stg.*.address)}"
  ]
}

output "rds_tableau_wip_endpoint" {
  value = [
    "${join("", aws_db_instance.internal_reporting_snapshot_wip.*.address)}"
  ]
}
