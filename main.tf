module "instance" {
  source    = "github.com/UKHomeOffice/connectivity-tester-tf"
  subnet_id = "${aws_subnet.subnet.id}"
  user_data = "CHECK_self=127.0.0.1:8080 CHECK_google=google.com:80 CHECK_googletls=google.com:443 LISTEN_HTTP=0.0.0.0:443 LISTEN_HTTP=0.0.0.0:3389 CHECK_GP=${var.greenplum_ip}:5432"
}

resource "aws_subnet" "subnet" {
  vpc_id     = "${var.apps_vpc_id}"
  cidr_block = "${var.dq_internal_dashboard_subnet_cidr}"

  tags {
    Name             = "sn-tableau-internal-${var.service}-${var.environment}-{az}"
    Service          = "${var.service}"
    Environment      = "${var.environment}"
    EnvironmentGroup = "${var.environment_group}"
  }
}

resource "aws_security_group" "sgrp" {
  vpc_id = "${var.apps_vpc_id}"

  ingress {
    from_port = "${var.https_from_port}"
    to_port   = "${var.https_to_port}"
    protocol  = "${var.https_protocol}"

    cidr_blocks = ["${var.dq_ops_ingress_cidr}",
      "${var.acp_prod_ingress_cidr}",
    ]
  }

  ingress {
    from_port   = "${var.RDP_from_port}"
    to_port     = "${var.RDP_to_port}"
    protocol    = "${var.RDP_protocol}"
    cidr_blocks = ["${var.dq_ops_ingress_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name             = "sg-internal-tableau-${var.service}-${var.environment}"
    Service          = "${var.service}"
    Environment      = "${var.environment}"
    EnvironmentGroup = "${var.environment_group}"
  }
}
