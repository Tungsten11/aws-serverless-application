output "api_invoke_url" {
  description = "Base URL for API Gateway"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/prod"
  sensitive   = true
}

