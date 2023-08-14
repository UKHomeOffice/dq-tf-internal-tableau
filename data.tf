data "aws_ami" "int_tableau_linux" {
  most_recent = true

  filter {
    name = "name"

    # "dq-tableau-linux-nnn" is used to pull exact image
    # "copied from*" is used to pull copy of nnn image copied to NotProd/Prod
    values = [
      "dq-tableau-linux-722 copied from*"
    ]
  }

  # "self" is used to ensure that NotProd uses image copied to NotProd account
  # and Prod uses image copied to Prod account
  owners = [
    "self"
  ]
}

data "aws_kms_key" "rds_kms_key" {
  key_id = "alias/aws/rds"
}
