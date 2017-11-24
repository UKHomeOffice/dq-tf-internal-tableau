variable "tableau_ami_id" {}
variable "tableau_instance_type" {}
variable "tableau_user_data" {}
variable "subnet_id" {}

variable "protocol" {}
variable "security_cidr" {}


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
}


