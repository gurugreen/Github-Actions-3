# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda (Allow all actions on all resources)
resource "aws_iam_policy" "allow_all_policy" {
  name        = "lambda_allow_all_policy"
  description = "Policy to allow all actions on all resources"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.allow_all_policy.arn
}

# Lambda Function
resource "aws_lambda_function" "example_lambda" {
  function_name    = "example_lambda_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  architectures     = ["x86_64"]
  memory_size      = 10240
  timeout          = 30
  ephemeral_storage {
    size = 512
  }
  package_type     = "Zip"
  # snap_start       = "None" # SnapStart not applied
  snap_start {
    apply_on = "None"
  }
  filename         = "./lambda_function.zip" # Path to your Lambda deployment package
  
  # # Runtime Management Configuration
  # runtime_management_config {
  #   update_runtime_on       = "Auto"
  #   runtime_update_mode     = "Function"
  # }
}

resource "aws_lambda_event_source_mapping" "example_mapping" {
  # event_source_arn = "arn:aws:sqs:region:account-id:queue-name" # Example: SQS
  event_source_arn = aws_sqs_queue.example_queue.arn
  function_name    = aws_lambda_function.example_lambda.function_name
  batch_size       = 10

  # Retry and event age settings
  maximum_retry_attempts = 2
  maximum_record_age_in_seconds = 21600
}

# # Lambda Function Event Invoke Config
# resource "aws_lambda_event_invoke_config" "example_invoke_config" {
#   function_name          = aws_lambda_function.example_lambda.function_name
#   maximum_event_age_in_seconds = 21600
#   maximum_retry_attempts = 2
# }

# API Gateway (api1)
resource "aws_apigatewayv2_api" "api1" {
  name          = "api1"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "api1_route" {
  api_id    = aws_apigatewayv2_api.api1.id
  route_key = "POST /accretion-posting"
}

resource "aws_apigatewayv2_integration" "api1_integration" {
  api_id             = aws_apigatewayv2_api.api1.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.example_lambda.invoke_arn
  payload_format_version = "2.0"
}

# API Gateway (api2)
resource "aws_apigatewayv2_api" "api2" {
  name          = "api2"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "api2_route" {
  api_id    = aws_apigatewayv2_api.api2.id
  route_key = "POST /depreciation-posting"
}

resource "aws_apigatewayv2_integration" "api2_integration" {
  api_id             = aws_apigatewayv2_api.api2.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.example_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_sqs_queue" "example_queue" {
  name = "example-queue"
}