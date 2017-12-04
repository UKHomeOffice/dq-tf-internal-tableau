variable "greenplum_ip" {
  default = false
  description = "IP address for Greenplum"
}

variable "acp_prod_ingress_cidr" {
  default = "10.5.0.0/16"
  description = "ACP Prod CIDR as per IP Addresses and CIDR blocks document"
}

variable "dq_ops_ingress_cidr" {
  default = "10.2.0.0/16"
  description = "DQ Ops CIDR as per IP Addresses and CIDR blocks document"
}

variable "dq_apps_cidr" {
  default = "10.1.0.0/16"
  description = "DQ Apps CIDR as per IP Addresses and CIDR blocks document"
}

variable "service" {
  default = "dq-dashboard-int"
  description = "As per naming standards in AWS-DQ-Network-Routing 0.4 document"
}

variable "environment" {
  default = "preprod"
  description = "As per naming standards in AWS-DQ-Network-Routing 0.4 document"
}

variable "environment_group" {
  default = "dq-apps"
  description = "As per naming standards in AWS-DQ-Network-Routing 0.4 document"
}

variable "apps_vpc_id" {
  default = false
  description = "Value obtained from Apps module"
}
