output "id" {
  description = "The ID of the secret."
  value       = azapi_resource.secret.id
}

output "name" {
  description = "The name of the secret."
  value       = azapi_resource.secret.name
}

output "resource_id" {
  description = "The Azure Resource ID of the secret."
  value       = azapi_resource.secret.id
}
