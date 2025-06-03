output "api_url" {
  description = "URL of the deployed API"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "rest_api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.main.id
}