data "aws_ami" "int_tableau_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "dq-tableau-linux-584"
    ]
  }

  owners = [
    "093401982388",
  ]
}

data "aws_kms_key" "rds_kms_key" {
  key_id = "alias/aws/rds"
}
