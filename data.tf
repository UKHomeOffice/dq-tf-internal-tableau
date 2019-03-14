data "aws_ami" "int_tableau_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-tableau-linux-100*",
    ]
  }

  owners = [
    "self",
  ]
}

data "aws_kms" "rds_kms_key" {
  most_recent = true

  filter {
    name = "alias"

    values = [
      "aws/rds",
    ]
  }

  owners = [
    "self",
  ]
}
