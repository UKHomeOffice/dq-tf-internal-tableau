# dq-tf-internal-tableau

This Terraform module has one subnet and deploys an EC2 instance representing a web server with postgress to a greenplum database. Allowing inbound HTTPS TCP traffic on port 443, and inbound RDP TCP traffic on port 3389 .


## Connectivity

| In/Out        | Type           | Protocol | FromPort| To Port | TLS |
| ------------- |:-------------:| -----:| -----:|-----:| -----:|
|INBOUND | RDP | TCP |3389 | 3389| TLS to Internal Tableau ELB |
|INBOUND | HTTPS | TCP | 443 | 443 | TLS to Internal Tableau ELB |
|INBOUND | HTTPS | TCP | 443 | 443 | TLS to Internal Tableau ELB |


## Usage

To run tests using the [tf testsuite](https://github.com/UKHomeOffice/dq-tf-testsuite):
```shell
drone exec --repo.trusted
```
To launch:
```shell
terraform apply
```

