data "aws_ami" "int_tableau_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-tableau-linux-91*",
    ]
  }

  owners = [
    "self",
  ]
}
