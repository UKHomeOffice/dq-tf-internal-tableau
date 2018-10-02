data "aws_region" "current" {
  current = true
}

data "aws_ami" "int_tableau" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-int-tableau-no1",
    ]
  }

  owners = [
    "self",
  ]
}
