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

data "aws_ami" "int_tableau_10_2" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-int-tableau-10-2",
    ]
  }

  owners = [
    "self",
  ]
}
