resource "aws_apigatewayv2_api" "api" {
  name          = var.api_domain_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.api_origins
  }

  # disable_execute_api_endpoint = true
}

resource "aws_apigatewayv2_integration" "any_route_lambda_function" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "any_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.any_route_lambda_function.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}
