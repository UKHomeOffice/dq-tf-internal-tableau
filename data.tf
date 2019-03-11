data "aws_ami" "int_tableau_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-tableau-linux-96*",
    ]
  }

  owners = [
    "self",
  ]
}
