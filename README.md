# dq-tf-internal-tableau

This Terraform module has two subnet and deploys an EC2 instance representing a web server and an RDS instance. Allowing inbound HTTPS TCP traffic on port 80, 22, 8850, 8060 and 5432.


## Connectivity

| In/Out        | Type           | Protocol | FromPort| To Port | Description |
| ------------- |:-------------:| -----:| -----:|-----:| -----:|
|INBOUND | SSH | TCP | 22 | 22 | Allow SSH login to EC2 |
|INBOUND | HTTP | TCP | 80 | 80 | Allow HTTP to Tableau software |
|INBOUND | TCP | TCP | 8850 | 8850 | Allow custom TCP for Tableau software |
|INBOUND | TCP | TCP | 8060 | 8060 | Allow custom TCP for Tableau software |
|INBOUND | TCP | TCP | 5432 | 5432 | Allow default TCP to PostgreSQL |

## Content overview

This repo controls the deployment of an application module.

It consists of the following core elements:

### main.tf

This file has the basic components for EC2 instances.
- Private subnet and route table association
- EC2 instances
- Security group for the EC2 instance

### variables.tf

Input data for resources within this repo.

### tests/e2e_test.py

Code and resource tester with mock data. It can be expanded by adding further definitions to the unit.

### rds.tf

Deploys an RDS instance as the Tableau Internal backend instance.

## User guide

### Prepare your local environment

This project currently depends on:

* drone v0.5+dev
* terraform v0.11.1+
* terragrunt v0.13.21+
* python v3.6.3+

Please ensure that you have the correct versions installed (it is not currently tested against the latest version of Drone)

### How to run/deploy

To run tests using the [tf testsuite](https://github.com/UKHomeOffice/dq-tf-testsuite):
```shell
drone exec --repo.trusted
```
To launch:
```shell
terragrunt plan
terragrunt apply
```

## FAQs

### The remote state isn't updating, what do I do?

If the CI process appears to be stuck with a stale `tf state` then run the following command to force a refresh:

```
terragrunt refresh
```
If the CI process is still failing after a refresh look for errors about items no longer available in AWS - say something that was deleted manually via the AWS console or CLI.
To explicitly delete the stale resource from TF state use the following command below. *Note:*```terragrunt state rm``` will not delete the resource from AWS it will unlink it from state only.

```shell
terragrunt state rm aws_resource_name
```
