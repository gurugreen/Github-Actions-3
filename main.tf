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
  memory_size      = 128
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
 }

# Create an API Gateway REST API
resource "aws_api_gateway_rest_api" "example_api" {
  name        = "example-api"
  description = "API Gateway for Lambda function"
}

# Create a resource (endpoint) for the API
resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "accretion-posting"
}

# Create a POST method for the resource
resource "aws_api_gateway_method" "example_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id
}

# Lambda integration with API Gateway
resource "aws_api_gateway_integration" "example_integration" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_post_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.example_lambda.arn}/invocations"
}

# Grant API Gateway permissions to invoke Lambda function
resource "aws_lambda_permission" "example_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.example_api.id}/*/POST/AccretionPosting"
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "example_deployment" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  # stage_name  = "Demo"

  depends_on = [
    aws_api_gateway_integration.example_integration,
    aws_api_gateway_method.example_post_method,
    aws_api_gateway_method.depreciation_post_method
  ]
}

# Optionally, create another resource and method for depreciation-posting (if needed)
resource "aws_api_gateway_resource" "depreciation_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "depreciation-posting"
}

resource "aws_api_gateway_method" "depreciation_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.depreciation_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id
}

resource "aws_api_gateway_integration" "depreciation_integration" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  resource_id = aws_api_gateway_resource.depreciation_resource.id
  http_method = aws_api_gateway_method.depreciation_post_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.example_lambda.arn}/invocations"
}

resource "aws_lambda_permission" "depreciation_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokeDepreciation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.example_api.id}/*/POST/DepreciationPosting"
}

data "aws_caller_identity" "current" {}

# Custom API Gateway Authorizer
resource "aws_api_gateway_authorizer" "custom_authorizer" {
  name                   = "CustomLambdaAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.example_api.id
  authorizer_uri         = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.custom_authorizer.arn}/invocations"
  identity_source        = "method.request.header.Authorization"
  type                   = "TOKEN"
  authorizer_result_ttl_in_seconds = 300
}

resource "aws_api_gateway_stage" "example_stage" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  stage_name  = "Demo"
  deployment_id = aws_api_gateway_deployment.example_deployment.id

  description = "Demo stage for API Gateway"

  # Stage Variables
  # variables = {
  #   some_variable = "value"  # Variable key-value pair
  # }
}