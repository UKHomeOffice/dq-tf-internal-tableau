variable "tableau_ami_id" {}
variable "tableau_instance_type" {}
variable "tableau_user_data" {}
variable "subnet_id" {}
variable "GREENPLUM_IP" {}

variable "protocol" {}
variable "ingress_cidr" {}
variable "egress_cidr" {}

variable "postgres_security_groups" {}

resource "aws_instance" "internal_tableau" {
  ami           = "${var.tableau_ami_id}"
  instance_type = "${var.tableau_instance_type}"
  subnet_id     = "${var.subnet_id}"

  user_data = "LISTEN_HTTP=0.0.0.0:443 CHECK_GP=${var.GREENPLUM_IP}:5432"

  tags {
    Name = "internal-tableau" # see naming scheme
  }
}

resource "aws_security_group" "internal_tableau" {
  name = "internal_tableau"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.ingress_cidr}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = "${var.egress_cidr}"
  }
}
