output "id" {
  description = "The ID of the target group."
  value       = azapi_resource.target_group.id
}

output "name" {
  description = "The name of the target group."
  value       = azapi_resource.target_group.name
}

output "resource_id" {
  description = "The Azure Resource ID of the target group."
  value       = azapi_resource.target_group.id
}
