data "aws_ami" "int_tableau_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-tableau-linux-232*",
    ]
  }

  owners = [
    "self",
  ]
}

data "aws_ami" "int_tableau_linux_upgrade" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-tableau-linux-232*",
    ]
  }

  owners = [
    "self",
  ]
}

data "aws_kms_key" "rds_kms_key" {
  key_id = "alias/aws/rds"
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}
