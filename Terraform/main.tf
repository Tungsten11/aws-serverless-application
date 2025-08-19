terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-v9"
    key            = "serverless-app/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-locks-v9"
    encrypt        = true
  }
}


# Package Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../build/lambda.zip"
}

# DynamoDB
resource "aws_dynamodb_table" "items" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# IAM Role + Policies
resource "aws_iam_role" "lambda_exec" {
  name = "serverless-lambda-exec"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Principal = { Service = "lambda.amazonaws.com" }, Effect = "Allow" }]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "ddb_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Lambda Function
resource "aws_lambda_function" "app" {
  function_name    = "serverless-app-fn"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.12"
  handler          = "app.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment { variables = { TABLE_NAME = aws_dynamodb_table.items.name } }
}

# API Gateway (HTTP API v2)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "serverless-app-api"
  protocol_type = "HTTP"
}
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.app.invoke_arn
}
resource "aws_apigatewayv2_route" "items_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /items"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true
}
resource "aws_lambda_permission" "api_gw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-error-alarm"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    FunctionName = aws_lambda_function.app.function_name
  }
  alarm_actions = [] # add SNS topic ARN for email alerts
}
