data "aws_ami" "linux_connectivity_tester" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "connectivity-tester-linux*",
    ]
  }

  owners = [
    "093401982388",
  ]
}

resource "aws_instance" "instance" {
  instance_type          = "t2.nano"
  ami                    = "${data.aws_ami.linux_connectivity_tester.id}"
  subnet_id              = "${aws_subnet.subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.sgrp.id}"]
  user_data              = "CHECK_self=127.0.0.1:8080 CHECK_google=google.com:80 CHECK_googletls=google.com:443 LISTEN_HTTP=0.0.0.0:443 LISTEN_HTTP=0.0.0.0:3389 CHECK_GP=${var.greenplum_ip}:5432"

  tags {
    Name             = "instance-tableau-internal-{1}-${var.service}-${var.environment}"
    Service          = "${var.service}"
    Environment      = "${var.environment}"
    EnvironmentGroup = "${var.environment_group}"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = "${var.apps_vpc_id}"
  cidr_block = "${var.apps_cidr}"

  tags {
    Name             = "sn-tableau-internal-${var.service}-${var.environment}-{az}"
    Service          = "${var.service}"
    Environment      = "${var.environment}"
    EnvironmentGroup = "${var.environment_group}"
  }
}

resource "aws_security_group" "sgrp" {
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = ["${var.ops_ingress_cidr}",
      "${var.acp_ingress_cidr}",
    ]
  }

  ingress {
    from_port   = 3389
    to_port     = 3889
    protocol    = "tcp"
    cidr_blocks = ["${var.ops_ingress_cidr}"]
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
