output "id" {
  description = "The resource ID of the origin group."
  value       = azapi_resource.origin_group.id
}

output "name" {
  description = "The name of the origin group."
  value       = azapi_resource.origin_group.name
}

output "origin_ids" {
  description = "The resource IDs of the origins."
  value       = { for key, origin in module.origin : key => origin.id }
}

output "origins" {
  description = "The origins created in this origin group."
  value = {
    for key, origin in module.origin : key => {
      id   = origin.id
      name = origin.name
    }
  }
}

output "resource_id" {
  description = "The resource ID of the origin group."
  value       = azapi_resource.origin_group.id
}
