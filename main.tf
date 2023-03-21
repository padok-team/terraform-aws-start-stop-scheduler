data "aws_region" "current" {}

locals {
  name_prefix = "${var.name}_scheduler"
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  count              = var.custom_iam_lambda_role ? 0 : 1
  name_prefix        = local.name_prefix
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = var.tags
}


resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count      = var.custom_iam_lambda_role ? 0 : 1
  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_autoscalinggroup" {
  statement {
    actions = [
      "autoscaling:DescribeScalingProcessTypes",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeTags",
      "autoscaling:SuspendProcesses",
      "autoscaling:ResumeProcesses",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:TerminateInstances",
      "eks:ListClusters",
      "eks:ListNodegroups",
      "eks:DescribeNodegroup"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_autoscalinggroup" {
  count = var.custom_iam_lambda_role ? 0 : 1

  name_prefix = "${local.name_prefix}_autoscaling"
  role        = aws_iam_role.lambda[0].id
  policy      = data.aws_iam_policy_document.lambda_autoscalinggroup.json
}

data "aws_iam_policy_document" "lambda_tagging_api" {
  statement {
    actions = [
      "tag:GetResources",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_tagging_api" {
  count = var.custom_iam_lambda_role ? 0 : 1

  name_prefix = "${local.name_prefix}_tagging_api"
  role        = aws_iam_role.lambda[0].id
  policy      = data.aws_iam_policy_document.lambda_tagging_api.json
}

data "aws_iam_policy_document" "lambda_rds" {
  statement {
    actions = [
      "rds:StartDBInstance",
      "rds:StopDBInstance",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_rds" {
  count = var.custom_iam_lambda_role ? 0 : 1

  name_prefix = "${local.name_prefix}_rds"
  role        = aws_iam_role.lambda[0].id
  policy      = data.aws_iam_policy_document.lambda_rds.json
}

data "aws_iam_policy_document" "lambda_ec2" {
  statement {
    actions = [
      "ec2:TerminateInstances",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_ec2" {
  count = var.custom_iam_lambda_role ? 0 : 1

  name_prefix = "${local.name_prefix}_ec2"
  role        = aws_iam_role.lambda[0].id
  policy      = data.aws_iam_policy_document.lambda_ec2.json
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function/"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_cloudwatch_log_group" "start_stop_scheduler" {
  name              = "/aws/lambda/${local.name_prefix}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_lambda_function" "start_stop_scheduler" {
  depends_on    = [aws_cloudwatch_log_group.start_stop_scheduler]
  filename      = data.archive_file.lambda_zip.output_path
  function_name = local.name_prefix
  role          = var.custom_iam_lambda_role ? var.custom_iam_lambda_role_arn : aws_iam_role.lambda[0].arn
  handler       = "scheduler.main.lambda_handler"
  timeout       = var.lambda_timeout

  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  runtime = "python3.8"

  environment {
    variables = {
      AWS_REGIONS  = var.aws_regions == null ? data.aws_region.current.name : join(", ", var.aws_regions)
      RDS_SCHEDULE = tostring(var.rds_schedule)
      ASG_SCHEDULE = tostring(var.asg_schedule)
      EC2_SCHEDULE = tostring(var.ec2_schedule)
    }
  }

  tags = var.tags
}


locals {
  start_schedulers = [for schedule in var.schedules : {
    name      = "start-${schedule.name}"
    action    = "start"
    cron      = schedule.start
    tag_key   = schedule.tag_key
    tag_value = schedule.tag_value
  } if schedule.start != ""]

  stop_schedulers = [for schedule in var.schedules : {
    name      = "stop-${schedule.name}"
    action    = "stop"
    cron      = schedule.stop
    tag_key   = schedule.tag_key
    tag_value = schedule.tag_value
  } if schedule.stop != ""]

  schedulers_map = { for scheduler in concat(local.start_schedulers, local.stop_schedulers) : scheduler.name => scheduler }
}


resource "aws_cloudwatch_event_rule" "start_stop" {
  for_each = local.schedulers_map

  name                = "${local.name_prefix}_${each.key}"
  schedule_expression = "cron(${each.value.cron})"
  description         = "${each.key} - ${each.value.tag_key}=${each.value.tag_value}"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "start_stop" {
  for_each = local.schedulers_map

  rule = aws_cloudwatch_event_rule.start_stop[each.key].id
  arn  = aws_lambda_function.start_stop_scheduler.arn
  input = jsonencode({
    "action" : each.value.action,
    "tag" : {
      "key" : each.value.tag_key,
      "value" : each.value.tag_value,
    }
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_start" {
  for_each = local.schedulers_map

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_stop_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_stop[each.key].arn
}
