locals {
  internal_reporting_dev_count     = var.environment == "prod" ? "0" : "1"
  internal_reporting_qa_count      = var.environment == "prod" ? "0" : "1"
  internal_reporting_stg_count     = var.environment == "prod" ? "1" : "1"
  internal_reporting_upgrade_count = var.environment == "prod" ? "0" : "1"
}

resource "aws_db_subnet_group" "rds" {
  name = "internal_tableau_rds_group"

  subnet_ids = [
    aws_subnet.subnet.id,
    aws_subnet.internal_tableau_az2.id,
  ]

  tags = {
    Name = "rds-subnet-group-${local.naming_suffix}"
  }
}

resource "aws_subnet" "internal_tableau_az2" {
  vpc_id                  = var.apps_vpc_id
  cidr_block              = var.dq_internal_dashboard_subnet_cidr_az2
  map_public_ip_on_launch = false
  availability_zone       = var.az2

  tags = {
    Name = "az2-subnet-${local.naming_suffix}"
  }
}

resource "aws_route_table_association" "internal_tableau_rt_rds" {
  subnet_id      = aws_subnet.internal_tableau_az2.id
  route_table_id = var.route_table_id
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
  vpc_id = var.apps_vpc_id

  ingress {
    from_port = var.rds_from_port
    to_port   = var.rds_to_port
    protocol  = var.rds_protocol

    cidr_blocks = [
      var.dq_ops_ingress_cidr,
      var.peering_cidr_block,
      var.dq_internal_dashboard_subnet_cidr,
      var.dq_internal_dashboard_subnet_cidr_az2,
      var.dq_lambda_subnet_cidr,
      var.dq_lambda_subnet_cidr_az2,
      var.dq_external_dashboard_subnet_cidr,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-db-${local.naming_suffix}"
  }
}

resource "aws_iam_role" "postgres" {
  name = "rds-postgres-role-${local.naming_suffix}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "monitoring.rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_db_instance" "postgres" {
  identifier                      = "postgres-${local.naming_suffix}"
  allocated_storage               = var.environment == "prod" ? "3300" : "700"
  storage_type                    = "gp2"
  engine                          = "postgres"
  engine_version                  = var.environment == "prod" ? "10.10" : "10.10"
  instance_class                  = var.environment == "prod" ? "db.m5.4xlarge" : "db.m5.2xlarge"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  username                        = random_string.username.result
  password                        = random_string.password.result
  name                            = var.database_name
  port                            = var.port
  backup_window                   = var.environment == "prod" ? "00:00-01:00" : "07:00-08:00"
  maintenance_window              = var.environment == "prod" ? "mon:01:00-mon:02:00" : "mon:08:00-mon:09:00"
  backup_retention_period         = 14
  deletion_protection             = true
  storage_encrypted               = true
  multi_az                        = true
  skip_final_snapshot             = true
  apply_immediately               = var.environment == "prod" ? "false" : "true"
  ca_cert_identifier              = var.environment == "prod" ? "rds-ca-2019" : "rds-ca-2019"

  performance_insights_enabled          = true
  performance_insights_retention_period = "7"

  monitoring_interval = "60"
  monitoring_role_arn = var.rds_enhanced_monitoring_role

  db_subnet_group_name   = aws_db_subnet_group.rds.id
  vpc_security_group_ids = [aws_security_group.internal_tableau_db.id]

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "rds-postgres-${local.naming_suffix}"
  }
}

module "rds_alarms" {
  source = "github.com/UKHomeOffice/dq-tf-cloudwatch-rds"

  naming_suffix                = local.naming_suffix
  environment                  = var.naming_suffix
  pipeline_name                = "internal-tableau"
  db_instance_id               = aws_db_instance.postgres.id
  free_storage_space_threshold = 250000000000 # 250GB free space
  read_latency_threshold       = 0.05         # 50 milliseconds
  write_latency_threshold      = 1            # 1 second
}

resource "aws_db_instance" "internal_reporting_snapshot_dev" {
  count                               = local.internal_reporting_dev_count
  snapshot_identifier                 = "internal-reporting-20190320-1133"
  auto_minor_version_upgrade          = "true"
  backup_retention_period             = "14"
  copy_tags_to_snapshot               = "false"
  db_subnet_group_name                = aws_db_subnet_group.rds.id
  deletion_protection                 = "false"
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = "false"
  identifier                          = "dev-postgres-${local.naming_suffix}"
  instance_class                      = "db.t3.large"
  iops                                = "0"
  kms_key_id                          = data.aws_kms_key.rds_kms_key.arn
  license_model                       = "postgresql-license"
  backup_window                       = var.environment == "prod" ? "00:00-01:00" : "07:00-08:00"
  maintenance_window                  = var.environment == "prod" ? "mon:01:00-mon:02:00" : "mon:08:00-mon:09:00"
  multi_az                            = "true"
  port                                = "5432"
  publicly_accessible                 = "false"
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  storage_type                        = "gp2"
  vpc_security_group_ids              = [aws_security_group.internal_tableau_db.id]
  ca_cert_identifier                  = var.environment == "prod" ? "rds-ca-2019" : "rds-ca-2019"
  engine_version                      = var.environment == "prod" ? "10.6" : "10.10"
  apply_immediately                   = var.environment == "prod" ? "false" : "true"

  performance_insights_enabled          = true
  performance_insights_retention_period = "7"

  monitoring_interval = "60"
  monitoring_role_arn = var.rds_enhanced_monitoring_role

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "dev-postgres-${local.naming_suffix}"
  }
}

resource "aws_db_instance" "internal_reporting_snapshot_qa" {
  count                               = local.internal_reporting_qa_count
  snapshot_identifier                 = "internal-reporting-20190318-1328"
  auto_minor_version_upgrade          = "true"
  backup_retention_period             = "14"
  copy_tags_to_snapshot               = "false"
  db_subnet_group_name                = aws_db_subnet_group.rds.id
  deletion_protection                 = "false"
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = "false"
  identifier                          = "qa-postgres-${local.naming_suffix}"
  instance_class                      = "db.t3.large"
  iops                                = "0"
  kms_key_id                          = data.aws_kms_key.rds_kms_key.arn
  license_model                       = "postgresql-license"
  backup_window                       = var.environment == "prod" ? "00:00-01:00" : "07:00-08:00"
  maintenance_window                  = var.environment == "prod" ? "mon:01:00-mon:02:00" : "mon:08:00-mon:09:00"
  multi_az                            = "true"
  port                                = "5432"
  publicly_accessible                 = "false"
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  storage_type                        = "gp2"
  vpc_security_group_ids              = [aws_security_group.internal_tableau_db.id]
  ca_cert_identifier                  = var.environment == "prod" ? "rds-ca-2019" : "rds-ca-2019"
  engine_version                      = var.environment == "prod" ? "10.6" : "10.10"
  apply_immediately                   = var.environment == "prod" ? "false" : "true"

  performance_insights_enabled          = true
  performance_insights_retention_period = "7"

  monitoring_interval = "60"
  monitoring_role_arn = var.rds_enhanced_monitoring_role

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "qa-postgres-${local.naming_suffix}"
  }
}

resource "aws_db_instance" "internal_reporting_snapshot_stg" {
  count                               = local.internal_reporting_stg_count
  snapshot_identifier                 = var.environment == "prod" ? "rds:postgres-internal-tableau-apps-prod-dq-2020-06-03-00-07" : "rds:postgres-internal-tableau-apps-notprod-dq-2020-03-23-07-07"
  auto_minor_version_upgrade          = "true"
  backup_retention_period             = "14"
  copy_tags_to_snapshot               = "false"
  db_subnet_group_name                = aws_db_subnet_group.rds.id
  deletion_protection                 = "false"
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = "false"
  identifier                          = "stg-postgres-${local.naming_suffix}"
  instance_class                      = var.environment == "prod" ? "db.m5.4xlarge" : "db.m5.2xlarge"
  iops                                = "0"
  kms_key_id                          = data.aws_kms_key.rds_kms_key.arn
  license_model                       = "postgresql-license"
  backup_window                       = var.environment == "prod" ? "00:00-01:00" : "07:00-08:00"
  maintenance_window                  = var.environment == "prod" ? "tue:01:00-tue:02:00" : "mon:08:00-mon:09:00"
  multi_az                            = "true"
  port                                = "5432"
  publicly_accessible                 = "false"
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  storage_type                        = "gp2"
  vpc_security_group_ids              = [aws_security_group.internal_tableau_db.id]
  ca_cert_identifier                  = var.environment == "prod" ? "rds-ca-2019" : "rds-ca-2019"
  monitoring_interval                 = "60"
  monitoring_role_arn                 = var.rds_enhanced_monitoring_role
  engine_version                      = var.environment == "prod" ? "10.10" : "10.10"
  apply_immediately                   = var.environment == "prod" ? "false" : "true"

  performance_insights_enabled          = true
  performance_insights_retention_period = "7"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "stg-postgres-${local.naming_suffix}"
  }
}

resource "aws_ssm_parameter" "rds_internal_tableau_username" {
  name  = "rds_internal_tableau_username"
  type  = "SecureString"
  value = random_string.username.result
}

resource "aws_ssm_parameter" "rds_internal_tableau_password" {
  name  = "rds_internal_tableau_password"
  type  = "SecureString"
  value = random_string.password.result
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
  value = random_string.service_username.result
}

resource "aws_ssm_parameter" "rds_internal_tableau_service_password" {
  name  = "rds_internal_tableau_service_password"
  type  = "SecureString"
  value = random_string.service_password.result
}

resource "aws_ssm_parameter" "rds_internal_tableau_postgres_endpoint" {
  name  = "rds_internal_tableau_postgres_endpoint"
  type  = "String"
  value = aws_db_instance.postgres.endpoint
}

resource "aws_ssm_parameter" "rds_internal_tableau_dev_endpoint" {
  count = local.internal_reporting_dev_count
  name  = "rds_internal_tableau_dev_endpoint"
  type  = "String"
  value = aws_db_instance.internal_reporting_snapshot_dev[0].endpoint
}

resource "aws_ssm_parameter" "rds_internal_tableau_qa_endpoint" {
  count = local.internal_reporting_qa_count
  name  = "rds_internal_tableau_qa_endpoint"
  type  = "String"
  value = aws_db_instance.internal_reporting_snapshot_qa[0].endpoint
}

resource "aws_ssm_parameter" "rds_internal_tableau_stg_endpoint" {
  count = local.internal_reporting_stg_count
  name  = "rds_internal_tableau_stg_endpoint"
  type  = "String"
  value = aws_db_instance.internal_reporting_snapshot_stg[0].endpoint
}
