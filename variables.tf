variable "naming_suffix" {
  default     = false
  description = "Naming suffix for tags, value passed from dq-tf-apps"
}

variable "http_from_port" {
  default     = 80
  description = "From port for HTTPS traffic"
}

variable "http_to_port" {
  default     = 80
  description = "To port for HTTPS traffic"
}

variable "http_protocol" {
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

variable "SSH_from_port" {
  default     = 22
  description = "From port for SSH traffic"
}

variable "SSH_to_port" {
  default     = 22
  description = "To port for SSH traffic"
}

variable "SSH_protocol" {
  default     = "tcp"
  description = "Protocol for SSH traffic"
}

variable "TSM_from_port" {
  default     = 8850
  description = "From port for TSM traffic"
}

variable "TSM_to_port" {
  default     = 8850
  description = "To port for TSM traffic"
}

variable "acp_prod_ingress_cidr" {
  default     = "10.5.0.0/16"
  description = "ACP Prod CIDR as per IP Addresses and CIDR blocks document"
}

variable "dq_ops_ingress_cidr" {
  default     = "10.2.0.0/16"
  description = "DQ Ops CIDR as per IP Addresses and CIDR blocks document"
}

variable "peering_cidr_block" {
  default     = "10.3.0.0/16"
  description = "DQ Peering CIDR as per IP Addresses and CIDR blocks document"
}

variable "dq_internal_dashboard_subnet_cidr" {
  default     = "10.1.12.0/24"
  description = "DQ Apps CIDR as per IP Addresses and CIDR blocks document"
}

variable "dq_internal_dashboard_instance_ip" {
  description = "IP address of EC2 instance"
  default     = "10.1.12.11"
}

variable "dq_internal_dashboard_blue_instance_ip" {
  description = "IP address of EC2 instance"
  default     = "10.1.12.12"
}

variable "dq_internal_dashboard_linux_instance_ip" {
  description = "IP address of EC2 instance"
  default     = "10.1.12.111"
}

variable "dq_internal_dashboard_linux_blue_instance_ip" {
  description = "IP address of EC2 instance"
  default     = "10.1.12.112"
}

variable "apps_vpc_id" {
  default     = false
  description = "Value obtained from Apps module"
}

variable "route_table_id" {
  default     = false
  description = "Value obtained from Apps module"
}

variable "az" {
  default     = "eu-west-2a"
  description = "Default availability zone for the subnet."
}

variable "key_name" {
  default = "test_instance"
}

variable "s3_archive_bucket" {
  description = "S3 archive bucket name"
}

variable "s3_archive_bucket_key" {
  description = "S3 archive bucket KMS key"
}

variable "s3_archive_bucket_name" {
  description = "Name of archive bucket"
}

variable "haproxy_private_ip" {
  description = "IP of HaProxy 1"
}
