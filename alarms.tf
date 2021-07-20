locals {
  alarm_naming_suffix = "${var.pipeline_name}-${var.naming_suffix}"
  path_module         = var.path_module != "unset" ? var.path_module : path.module

  thresholds = {
    CPUUtilizationThreshold   = min(max(var.cpu_utilization_threshold, 0), 100)
    AvailableMemoryThreshold  = max(var.available_memory_threshold, 0)
    UsedStorageSpaceThreshold = max(var.used_storage_space_threshold, 0)

  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_too_high_0" {
  count               = var.environment == "prod" ? "1" : "1"
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
    InstanceId = aws_instance.int_tableau_linux[0].id
  }

  depends_on = [
    aws_instance.int_tableau_linux[0]
  ]

  lifecycle {
    ignore_changes = [
      dimensions,
    ]
  }
}

resource "aws_cloudwatch_metric_alarm" "available_memory_too_low_0" {
  count               = var.environment == "prod" ? "1" : "1"
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
    InstanceId = aws_instance.int_tableau_linux[0].id
  }

  depends_on = [
    aws_instance.int_tableau_linux[0]
  ]
}

resource "aws_cloudwatch_metric_alarm" "Used_storage_space_0" {
  count               = var.environment == "prod" ? "1" : "1"
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
    InstanceId = aws_instance.int_tableau_linux[0].id,
    path       = "/",
    fstype     = "xfs",
  }

  depends_on = [
    aws_instance.int_tableau_linux[0]
  ]

  lifecycle {
    ignore_changes = [
      dimensions,
    ]
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_too_high_1" {
  count               = var.environment == "prod" ? "1" : "0"
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
    InstanceId = aws_instance.int_tableau_linux[1].id
  }

  depends_on = [
    aws_instance.int_tableau_linux[1]
  ]

}

resource "aws_cloudwatch_metric_alarm" "available_memory_too_low_1" {
  count               = var.environment == "prod" ? "1" : "0"
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
    InstanceId = aws_instance.int_tableau_linux[1].id
  }

  depends_on = [
    aws_instance.int_tableau_linux[1]
  ]

  lifecycle {
    ignore_changes = [
      dimensions,
    ]
  }
}

resource "aws_cloudwatch_metric_alarm" "Used_storage_space_1" {
  count               = var.environment == "prod" ? "1" : "0"
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
    InstanceId = aws_instance.int_tableau_linux[1].id,
    path       = "/",
    fstype     = "xfs",
  }

  depends_on = [
    aws_instance.int_tableau_linux[1]
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
#     InstanceId = aws_instance.int_tableau_linux[0].id
#   }
#
#   depends_on = [
#     aws_instance.int_tableau_linux[0]
#   ]
# }


##########
#  Data  #
##########
data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__ec2_policy_ID"

  statement {
    sid = "__ec2_statement_ID"

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    effect    = "Allow"
    resources = [aws_sns_topic.ec2.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }
  }

  statement {
    sid       = "Allow CloudwatchEvents"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.ec2.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }

  statement {
    sid       = "Allow EC2 Event Notification"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.ec2.arn]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#########
# SNS   #
#########

resource "aws_sns_topic" "ec2" {
  name = var.pipeline_name
}


resource "aws_sns_topic_policy" "ec2" {
  arn    = aws_sns_topic.ec2.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = aws_sns_topic.ec2.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_slack.arn
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.ec2.arn
}
