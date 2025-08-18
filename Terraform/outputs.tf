output "api_invoke_url" {
  description = "Base URL for API Gateway"
  value       = "${aws_apigatewayv2_api.serverless-app-api.api_endpoint}/prod"
}

