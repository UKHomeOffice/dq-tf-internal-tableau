variable "environment" {
}

variable "naming_suffix" {
}

variable "pipeline_name" {
}

variable "swap_alarm" {
  description = "Switch to turn off Swap monitoring (required for MSSQL). Accepted values are 'false' to turn off and 'true' to excplicitly turn on"
  default     = "true"
}

variable "path_module" {
  default = "unset"
}

variable "ec2_instance_id" {
  description = "The instance ID of the RDS database instance that you want to monitor."
  type        = string
}

variable "cpu_utilization_threshold" {
  description = "The maximum percentage of CPU utilization."
  type        = string
  default     = 80
}

variable "available_memory_threshold" {
  description = "The percentage of available memory."
  type        = string
  default     = 20
}

variable "used_storage_space_threshold" {
  description = "The minimum amount of available storage space in Byte."
  type        = string
  default     = 80
}
