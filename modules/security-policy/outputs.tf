output "id" {
  description = "The ID of the security policy."
  value       = azapi_resource.security_policy.id
}

output "name" {
  description = "The name of the security policy."
  value       = azapi_resource.security_policy.name
}

output "resource_id" {
  description = "The Azure Resource ID of the security policy."
  value       = azapi_resource.security_policy.id
}
