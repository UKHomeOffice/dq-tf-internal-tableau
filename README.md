# DQ Terraform Module

Deploying an ami to an instance, setting up a security group that allows http traffic. Listening on ports 5432 and 443.

Requires the env vars `TF_VAR_aws_access_key` and `TF_VAR_aws_secret_key` to be set.

## Usage

To run tests with the [tf testrunner](https://github.com/UKHomeOffice/tf-testrunner) framework:
```shell
drone5 exec --repo.trusted
```
To launch:
```shell
terraform apply
```

