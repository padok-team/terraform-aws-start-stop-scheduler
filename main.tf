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
