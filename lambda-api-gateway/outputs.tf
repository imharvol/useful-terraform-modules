output "api_function_role_name" {
  description = "Function role name"
  value       = aws_iam_role.api_function.name
}

output "api_function_arn" {
  description = "Function arn"
  value       = aws_iam_role.api_function.arn
}
