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

data "aws_kms_key" "rds_kms_key" {
  key_id = "alias/rds"
}
