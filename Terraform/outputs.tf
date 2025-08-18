output "api_invoke_url" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/prod"
}

output "api_invoke_url" {
  description = "Base URL for API Gateway"
  value       = aws_api_gateway_deployment.api.invoke_url
}
