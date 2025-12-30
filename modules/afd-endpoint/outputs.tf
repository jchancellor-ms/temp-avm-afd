output "host_name" {
  description = "The host name of the AFD endpoint."
  value       = azapi_resource.afd_endpoint.output.properties.hostName
}

output "id" {
  description = "The resource ID of the AFD Endpoint."
  value       = azapi_resource.afd_endpoint.id
}

output "location" {
  description = "The location the resource was deployed into."
  value       = azapi_resource.afd_endpoint.location
}

output "name" {
  description = "The name of the AFD Endpoint."
  value       = azapi_resource.afd_endpoint.name
}

output "resource_id" {
  description = "The resource ID of the AFD Endpoint."
  value       = azapi_resource.afd_endpoint.id
}

output "route_ids" {
  description = "The resource IDs of the routes."
  value       = { for key, route in module.route : key => route.id }
}

output "routes" {
  description = "The routes created for this AFD endpoint."
  value = {
    for key, route in module.route : key => {
      id   = route.id
      name = route.name
    }
  }
}
