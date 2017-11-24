variable "tableau_ami_id" {}
variable "tableau_instance_type" {}
variable "tableau_user_data" {}

variable "protocol" {}
variable "security_cidr" {}

variable "vpc_id" {}
variable "subnet_cidr" {}

resource "aws_instance" "internal_tableau" {
  ami           = "${var.tableau_ami_id}"
  instance_type = "${var.tableau_instance_type}"

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
}

resource "aws_subnet" "internal_tableau" {
  vpc_id     = "${var.vpc_id}"
  cidr_block = "${var.subnet_cidr}"
  
  tags {
    Name = "internal_tableau"
  }
}

