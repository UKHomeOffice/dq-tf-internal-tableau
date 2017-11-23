variable "tableau_ami_id" {}
variable "tableau_instance_type" {}

resource "aws_instance" "internal_tableau" {
  ami           = "${var.tableau_ami_id}"
  instance_type = "${var.tableau_instance_type}"

  tags {
    Name = "internal-tableau"
  }
}
