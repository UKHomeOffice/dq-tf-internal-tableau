variable "greenplum_ip" {
  default = false
}

variable "acp_ingress_cidr" {
  type = "string"
}

variable "ops_ingress_cidr" {
  type = "string"
}

variable "apps_cidr" {
  type = "string"
}

variable "service" {
  default = ""
}

variable "environment" {
  default = ""
}

variable "environment_group" {
  default = ""
}

variable "apps_vpc_id" {
  default = false
}
