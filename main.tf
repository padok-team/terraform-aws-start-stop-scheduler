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
  name               = "start_stop_scheduler_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
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
  name   = "start_stop_scheduler_autoscaling_policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_autoscalinggroup.json
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function/"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "start_stop_scheduler" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "start_stop_scheduler"
  role          = aws_iam_role.lambda.arn
  handler       = "scheduler.main.lambda_handler"
  timeout       = 30

  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  runtime = "python3.8"

  environment {
    variables = {
      FOO = "bar"
    }
  }
}

resource "aws_cloudwatch_event_rule" "start" {
  name_prefix         = "start_stop_scheduler"
  schedule_expression = "cron(*/20 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "start" {
  rule  = aws_cloudwatch_event_rule.start.id
  arn   = aws_lambda_function.start_stop_scheduler.arn
  input = <<EOF
{
  "action": "start",
  "tag": {
    "key": "start_stop_scheduler_group",
    "value": "test_asg_2"
  }
}
EOF
}

resource "aws_lambda_permission" "allow_cloudwatch_start" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_stop_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start.arn
  #  statement_id_prefix = "value"
}

resource "aws_cloudwatch_event_rule" "stop" {
  name_prefix         = "start_stop_scheduler"
  schedule_expression = "cron(10/20 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "stop" {
  rule  = aws_cloudwatch_event_rule.stop.id
  arn   = aws_lambda_function.start_stop_scheduler.arn
  input = <<EOF
{
  "action": "stop",
  "tag": {
    "key": "start_stop_scheduler_group",
    "value": "test_asg_2"
  }
}
EOF
}

resource "aws_lambda_permission" "allow_cloudwatch_stop" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_stop_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop.arn
  #  statement_id_prefix = "value"
}
