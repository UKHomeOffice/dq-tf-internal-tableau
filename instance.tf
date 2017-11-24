variable "tableau_ami_id" {}
variable "tableau_instance_type" {}
variable "tableau_user_data" {}
variable "subnet_id" {}

variable "protocol" {}
variable "security_cidr" {}

variable "postgres_security_groups" {}


resource "aws_instance" "internal_tableau" {
  ami           = "${var.tableau_ami_id}"
  instance_type = "${var.tableau_instance_type}"
  subnet_id = "${var.subnet_id}"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags {
    Name = "internal-tableau"
  }
}

resource "aws_security_group" "internal_tableau" {
  name = "internal_tableau"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "${var.protocol}"
    cidr_blocks = "${var.security_cidr}"
  }

  # gp
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${var.security_groups}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = "${var.security_cidr}"
  }
}


