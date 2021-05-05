data "aws_region" "current" {}

locals {
  name_prefix = "${var.name}_start_stop_scheduler"
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
  name_prefix        = local.name_prefix
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = var.tags
}


resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
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
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_autoscalinggroup" {
  name_prefix = "${local.name_prefix}_autoscaling"
  role        = aws_iam_role.lambda.id
  policy      = data.aws_iam_policy_document.lambda_autoscalinggroup.json
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function/"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_cloudwatch_log_group" "start_stop_scheduler" {
  name              = "/aws/lambda/${aws_lambda_function.start_stop_scheduler.function_name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_lambda_function" "start_stop_scheduler" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = local.name_prefix
  role          = aws_iam_role.lambda.arn
  handler       = "scheduler.main.lambda_handler"
  timeout       = var.lambda_timeout

  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  runtime = "python3.8"

  environment {
    variables = {
      AWS_REGIONS  = var.aws_regions == null ? data.aws_region.current.name : join(", ", var.aws_regions)
      RDS_SCHEDULE = tostring(var.rds_schedule)
      ASG_SCHEDULE = tostring(var.asg_schedule)
    }
  }

  tags = var.tags
}

locals {
  flatten_starts = { for index, v in flatten([for sched in var.schedules : [
    for key, value in sched.starts : {
      tag   = sched.tag,
      start = { cron = value, description = key },
    }
  ]]) : index => v }

  flatten_stops = { for index, v in flatten([for sched in var.schedules : [
    for key, value in sched.stops : {
      tag  = sched.tag,
      stop = { cron = value, description = key },
    }
  ]]) : index => v }
}

resource "aws_cloudwatch_event_rule" "start" {
  for_each = local.flatten_starts

  name_prefix         = "${local.name_prefix}_start"
  schedule_expression = "cron(${each.value.start.cron})"
  description         = "Start ressources with tag ${each.value.tag.key}=${each.value.tag.value} with cron '${each.value.start.description}'"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "start" {
  for_each = local.flatten_starts

  rule = aws_cloudwatch_event_rule.start[each.key].id
  arn  = aws_lambda_function.start_stop_scheduler.arn
  input = jsonencode({
    "action" : "start",
    "tag" : {
      "key" : each.value.tag.key,
      "value" : each.value.tag.value,
    }
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_start" {
  for_each = local.flatten_starts

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_stop_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start[each.key].arn
}


resource "aws_cloudwatch_event_rule" "stop" {
  for_each = local.flatten_stops

  name_prefix         = "${local.name_prefix}_stop"
  schedule_expression = "cron(${each.value.stop.cron})"
  description         = "Stop ressources with tag ${each.value.tag.key}=${each.value.tag.value} with cron '${each.value.stop.description}'"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "stop" {
  for_each = local.flatten_stops

  rule = aws_cloudwatch_event_rule.stop[each.key].id
  arn  = aws_lambda_function.start_stop_scheduler.arn
  input = jsonencode({
    "action" : "stop",
    "tag" : {
      "key" : each.value.tag.key,
      "value" : each.value.tag.value,
    }
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_stop" {
  for_each = local.flatten_stops

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_stop_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop[each.key].arn
}
