locals {
  naming_suffix = "${var.ec2_instance_id}-${var.naming_suffix}"
  path_module   = var.path_module != "unset" ? var.path_module : path.module

  thresholds = {
    CPUUtilizationThreshold   = min(max(var.cpu_utilization_threshold, 0), 100)
    AvailableMemoryThreshold  = max(var.available_memory_threshold, 0)
    UsedStorageSpaceThreshold = max(var.used_storage_space_threshold, 0)

  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_too_high" {
  alarm_name          = "${var.pipeline_name}-CPU-Utilization-too-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "600"
  statistic           = "Average"
  threshold           = local.thresholds["CPUUtilizationThreshold"]
  alarm_description   = "Average EC2 Instance CPU utilization over last 10 minutes too high"
  alarm_actions       = [aws_sns_topic.ec2.arn]
  ok_actions          = [aws_sns_topic.ec2.arn]

  dimensions = {
    InstanceId = var.ec2_instance_id
  }

  depends_on = [
    var.ec2_instance_id
  ]

}

resource "aws_cloudwatch_metric_alarm" "available_memory_too_low" {
  alarm_name          = "${var.pipeline_name}-available-memory-too-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "mem_available_percent"
  namespace           = "CWAgent"
  period              = "600"
  statistic           = "Average"
  threshold           = local.thresholds["AvailableMemoryThreshold"]
  alarm_description   = "Average available memory over last 10 minutes"
  alarm_actions       = [aws_sns_topic.ec2.arn]
  ok_actions          = [aws_sns_topic.ec2.arn]

  dimensions = {
    InstanceId = var.ec2_instance_id
  }

  depends_on = [
    var.ec2_instance_id
  ]
}

resource "aws_cloudwatch_metric_alarm" "Used_storage_space" {
  alarm_name          = "${var.pipeline_name}-used-storage-space"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "600"
  statistic           = "Average"
  threshold           = local.thresholds["UsedStorageSpaceThreshold"]
  alarm_description   = "Average database free storage space over last 10 minutes too low"
  alarm_actions       = [aws_sns_topic.ec2.arn]
  ok_actions          = [aws_sns_topic.ec2.arn]

  dimensions = {
    InstanceId = var.ec2_instance_id,
    path       = "/",
    fstype     = "xfs",
  }

  depends_on = [
    var.ec2_instance_id
  ]
}
# 
# resource "aws_cloudwatch_metric_alarm" "health" {
#   alarm_name          = "web-health-alarm"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "StatusCheckFailed"
#   namespace           = "AWS/EC2"
#   period              = "120"
#   statistic           = "Average"
#   threshold           = "1"
#   alarm_description   = "This metric monitors ec2 health status"
#   alarm_actions       = [aws_sns_topic.ec2.arn]
#   ok_actions          = [aws_sns_topic.ec2.arn]
#
#   dimensions = {
#     InstanceId = var.ec2_instance_id
#   }
#
#   depends_on = [
#     var.ec2_instance_id
#   ]
# }
