data "aws_ami" "int_tableau" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-tableau-7*",
    ]
  }

  owners = [
    "self",
  ]
}
