data "aws_ami" "int_tableau_linux" {
  most_recent = true

  filter {
    name = "name"

    # "dq-tableau-linux-nnn" is used to pull exact image
    # "copied from*" is used to pull copy of nnn image copied to NotProd/Prod
    #values = [
    #  "dq-tableau-linux-667 copied from*"
    #]

    # TEMPORARILY hardcoding to 533 (the version used in Prod)
    values = [
      "dq-tableau-linux-533"
    ]

  }

  # "self" is used to ensure that NotProd uses image copied to NotProd account
  # and Prod uses image copied to Prod account
  #owners = [
  #  "self",
  #]

  # TEMPORARILY using the CI account - to use the CI AMI in NotProd & Prod
  owners = [
    "093401982388",
  ]

}

data "aws_kms_key" "rds_kms_key" {
  key_id = "alias/aws/rds"
}
