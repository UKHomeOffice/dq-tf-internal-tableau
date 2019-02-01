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

  tags {
    Name = "sg-${local.naming_suffix}"
  }
}

resource "aws_security_group_rule" "allow_bastion" {
  type            = "ingress"
  description     = "Postgres from the Bastion host"
  from_port       = "${var.rds_from_port}"
  to_port         = "${var.rds_to_port}"
  protocol        = "${var.rds_protocol}"
  cidr_blocks = [
    "${var.var.dq_ops_ingress_cidr}",
    "${var.peering_cidr_block}",
  ]

  security_group_id = "${aws_security_group.internal_tableau_db.id}"
}

resource "aws_security_group_rule" "allow_db_lambda" {
  type            = "ingress"
  description     = "Postgres from the Lambda subnet"
  from_port       = "${var.rds_from_port}"
  to_port         = "${var.rds_to_port}"
  protocol        = "${var.rds_protocol}"
  cidr_blocks = [
    "${var.dq_lambda_subnet_cidr}",
    "${var.dq_lambda_subnet_cidr_az2}",
  ]

  security_group_id = "${aws_security_group.internal_tableau_db.id}"
}

resource "aws_security_group_rule" "allow_db_out" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = -1
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.internal_tableau_db.id}"
}

resource "aws_db_instance" "postgres" {
  identifier              = "int-tableau-postgres-${local.naming_suffix}"
  allocated_storage       = 300 
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "10.4"
  instance_class          = "db.t3.large"
  username                = "${random_string.username.result}"
  password                = "${random_string.password.result}"
  name                    = "${var.database_name}"
  port                    = "${var.port}"
  backup_window           = "00:00-01:00"
  maintenance_window      = "mon:01:30-mon:02:30"
  backup_retention_period = 14
  storage_encrypted       = true
  multi_az                = true
  skip_final_snapshot     = true

  db_subnet_group_name   = "${aws_db_subnet_group.rds.id}"
  vpc_security_group_ids = ["${aws_security_group.internal_tableau_db.id}"]

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = "internal_tableau-postgres-${local.naming_suffix}"
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
