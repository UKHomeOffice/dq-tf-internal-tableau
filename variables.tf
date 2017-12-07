variable "https_from_port" {
  default     = 443
  description = "From port for HTTPS traffic"
}

variable "https_to_port" {
  default     = 443
  description = "To port for HTTPS traffic"
}

variable "https_protocol" {
  default     = "tcp"
  description = "Protocol for HTTPS traffic"
}

variable "RDP_from_port" {
  default     = 3389
  description = "From port for RDP traffic"
}

variable "RDP_to_port" {
  default     = 3389
  description = "To port for RDP traffic"
}

variable "RDP_protocol" {
  default     = "tcp"
  description = "Protocol for RDP traffic"
}

variable "greenplum_ip" {
  default     = false
  description = "IP address for Greenplum"
}

variable "acp_prod_ingress_cidr" {
  default     = "10.5.0.0/16"
  description = "ACP Prod CIDR as per IP Addresses and CIDR blocks document"
}

variable "dq_ops_ingress_cidr" {
  default     = "10.2.0.0/16"
  description = "DQ Ops CIDR as per IP Addresses and CIDR blocks document"
}

variable "dq_internal_dashboard_subnet_cidr" {
  default     = "10.1.12.0/24"
  description = "DQ Apps CIDR as per IP Addresses and CIDR blocks document"
}

variable "service" {
  default     = "dq-dashboard-int"
  description = "As per naming standards in AWS-DQ-Network-Routing 0.4 document"
}

variable "environment" {
  default     = "preprod"
  description = "As per naming standards in AWS-DQ-Network-Routing 0.4 document"
}

variable "environment_group" {
  default     = "dq-apps"
  description = "As per naming standards in AWS-DQ-Network-Routing 0.4 document"
}

variable "apps_vpc_id" {
  default     = false
  description = "Value obtained from Apps module"
}

variable "route_table_id" {
  default     = false
  description = "Value obtained from Apps module"
}
