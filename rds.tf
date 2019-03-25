resource "aws_db_subnet_group" "rds" {
  name = "internal_tableau_rds_group"

  subnet_ids = [
    "${aws_subnet.subnet.id}",
    "${aws_subnet.internal_tableau_az2.id}",
  ]

  tags {
    Name = "rds-subnet-group-${local.naming_suffix}"
  }
}

resource "aws_subnet" "internal_tableau_az2" {
  vpc_id                  = "${var.apps_vpc_id}"
  cidr_block              = "${var.dq_internal_dashboard_subnet_cidr_az2}"
  map_public_ip_on_launch = false
  availability_zone       = "${var.az2}"

  tags {
    Name = "az2-subnet-${local.naming_suffix}"
  }
}

resource "aws_route_table_association" "internal_tableau_rt_rds" {
  subnet_id      = "${aws_subnet.internal_tableau_az2.id}"
  route_table_id = "${var.route_table_id}"
}

resource "random_string" "password" {
  length  = 16
  special = false
}

resource "random_string" "username" {
  length  = 8
  special = false
  number  = false
}

resource "aws_security_group" "internal_tableau_db" {
  vpc_id = "${var.apps_vpc_id}"

  ingress {
    from_port = "${var.rds_from_port}"
    to_port   = "${var.rds_to_port}"
    protocol  = "${var.rds_protocol}"

    cidr_blocks = [
      "${var.dq_ops_ingress_cidr}",
      "${var.peering_cidr_block}",
      "${var.dq_internal_dashboard_subnet_cidr}",
      "${var.dq_internal_dashboard_subnet_cidr_az2}",
      "${var.dq_lambda_subnet_cidr}",
      "${var.dq_lambda_subnet_cidr_az2}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "sg-db-${local.naming_suffix}"
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = "postgres-${local.naming_suffix}"
  allocated_storage       = "${var.postgres_allocated_storage}"
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "10.6"
  instance_class          = "db.m5.2xlarge"
  username                = "${random_string.username.result}"
  password                = "${random_string.password.result}"
  name                    = "${var.database_name}"
  port                    = "${var.port}"
  backup_window           = "00:00-01:00"
  maintenance_window      = "mon:16:05-mon:17:35"
  backup_retention_period = 14
  storage_encrypted       = true
  multi_az                = true
  skip_final_snapshot     = true
  apply_immediately       = "${var.apply_immediately}"

  db_subnet_group_name   = "${aws_db_subnet_group.rds.id}"
  vpc_security_group_ids = ["${aws_security_group.internal_tableau_db.id}"]

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = "rds-postgres-${local.naming_suffix}"
  }
}

resource "aws_db_instance" "internal_reporting_snapshot_dev" {
  count                               = "${var.rds_count_notprod}"
  snapshot_identifier                 = "internal-reporting-20190320-1133"
  auto_minor_version_upgrade          = "true"
  backup_retention_period             = "14"
  backup_window                       = "00:00-01:00"
  copy_tags_to_snapshot               = "false"
  db_subnet_group_name                = "${aws_db_subnet_group.rds.id}"
  deletion_protection                 = "false"
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = "false"
  identifier                          = "dev-postgres-${local.naming_suffix}"
  instance_class                      = "db.t3.large"
  iops                                = "0"
  kms_key_id                          = "${data.aws_kms_key.rds_kms_key.arn}"
  license_model                       = "postgresql-license"
  maintenance_window                  = "mon:01:30-mon:02:30"
  monitoring_interval                 = "0"
  multi_az                            = "true"
  port                                = "5432"
  publicly_accessible                 = "false"
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  storage_type                        = "gp2"
  vpc_security_group_ids              = ["${aws_security_group.internal_tableau_db.id}"]

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = "dev-postgres-${local.naming_suffix}"
  }
}

resource "aws_db_instance" "internal_reporting_snapshot_qa" {
  count                               = "${var.rds_count_notprod}"
  snapshot_identifier                 = "internal-reporting-20190318-1328"
  auto_minor_version_upgrade          = "true"
  backup_retention_period             = "14"
  backup_window                       = "00:00-01:00"
  copy_tags_to_snapshot               = "false"
  db_subnet_group_name                = "${aws_db_subnet_group.rds.id}"
  deletion_protection                 = "false"
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = "false"
  identifier                          = "qa-postgres-${local.naming_suffix}"
  instance_class                      = "db.t3.large"
  iops                                = "0"
  kms_key_id                          = "${data.aws_kms_key.rds_kms_key.arn}"
  license_model                       = "postgresql-license"
  maintenance_window                  = "mon:01:30-mon:02:30"
  monitoring_interval                 = "0"
  multi_az                            = "true"
  port                                = "5432"
  publicly_accessible                 = "false"
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  storage_type                        = "gp2"
  vpc_security_group_ids              = ["${aws_security_group.internal_tableau_db.id}"]

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = "qa-postgres-${local.naming_suffix}"
  }
}

resource "aws_ssm_parameter" "rds_internal_tableau_username" {
  name  = "rds_internal_tableau_username"
  type  = "SecureString"
  value = "${random_string.username.result}"
}

resource "aws_ssm_parameter" "rds_internal_tableau_password" {
  name  = "rds_internal_tableau_password"
  type  = "SecureString"
  value = "${random_string.password.result}"
}

resource "random_string" "service_username" {
  length  = 8
  special = false
  number  = false
}

resource "random_string" "service_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "rds_internal_tableau_service_username" {
  name  = "rds_internal_tableau_service_username"
  type  = "SecureString"
  value = "${random_string.service_username.result}"
}

resource "aws_ssm_parameter" "rds_internal_tableau_service_password" {
  name  = "rds_internal_tableau_service_password"
  type  = "SecureString"
  value = "${random_string.service_password.result}"
}

resource "aws_ssm_parameter" "rds_internal_tableau_postgres_endpoint" {
  name  = "rds_internal_tableau_postgres_endpoint"
  type  = "String"
  value = "${aws_db_instance.postgres.endpoint}"
}

resource "aws_ssm_parameter" "rds_internal_tableau_dev_endpoint" {
  count = "${var.rds_count_notprod}"
  name  = "rds_internal_tableau_dev_endpoint"
  type  = "String"
  value = "${aws_db_instance.internal_reporting_snapshot_dev.endpoint}"
}

resource "aws_ssm_parameter" "rds_internal_tableau_qa_endpoint" {
  count = "${var.rds_count_notprod}"
  name  = "rds_internal_tableau_qa_endpoint"
  type  = "String"
  value = "${aws_db_instance.internal_reporting_snapshot_qa.endpoint}"
}
