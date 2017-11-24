provider "aws" {
  access_key = "${var.TF_VAR_aws_access_key}"
  secret_key = "${var.TF_VAR_aws_access_key}"
  region = "${var.region}"
}

