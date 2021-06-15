terraform {
  required_version = ">= 0.12"
  required_providers {
    aws    = "~> 2.70"
    random = "~> 2.3"
  }

}

module "aws_global" {
  providers = {
    aws.global = aws
  }
  source = "../mymodule/cloudwatch-ec2"

}
