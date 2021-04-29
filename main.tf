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

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "start_stop_scheduler" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "start_stop_scheduler"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.lambda_handler"

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
  schedule_expression = "cron(*/1 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "start" {
  rule  = aws_cloudwatch_event_rule.start.id
  arn   = aws_lambda_function.start_stop_scheduler.arn
  input = <<EOF
{
  "action": "square root",
  "number": 361
}
EOF
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_stop_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start.arn
  #  statement_id_prefix = "value"
}
