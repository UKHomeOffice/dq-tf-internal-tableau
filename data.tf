data "aws_ami" "int_tableau" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-tableau-17*",
    ]
  }

  owners = [
    "self",
  ]
}
