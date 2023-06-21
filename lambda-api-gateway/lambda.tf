resource "aws_iam_role" "api_function" {
  name = "${replace(var.api_domain_name, ".", "-")}-api-function-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
    }
  )
}

resource "aws_lambda_function" "api" {
  function_name = "${replace(var.api_domain_name, ".", "-")}-api-function"

  filename         = "function.zip"
  source_code_hash = filebase64sha256("function.zip")
  layers           = var.function_layers

  role    = aws_iam_role.api_function.arn
  runtime = "nodejs16.x"
  handler = "index.handler"

  environment {
    variables = var.function_environment_variables
  }
}

resource "aws_cloudwatch_log_group" "api_function" {
  name = "/aws/lambda/${aws_lambda_function.api.function_name}"
}

resource "aws_iam_policy" "api_function_logging" {
  name = "${var.api_domain_name}-api-function-logging-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "${aws_cloudwatch_log_group.api_function.arn}:*",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_function_logging" {
  role       = aws_iam_role.api_function.name
  policy_arn = aws_iam_policy.api_function_logging.arn
}

resource "aws_lambda_permission" "api_function" {
  statement_id  = "Allow"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/*"
}
