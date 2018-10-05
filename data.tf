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

data "aws_ami" "int_tableau_2018_02" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-int-tableau-2018-02",
    ]
  }

  owners = [
    "self",
  ]
}
