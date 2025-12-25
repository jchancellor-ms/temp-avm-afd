output "id" {
  description = "The resource ID of the custom domain."
  value       = azapi_resource.custom_domain.id
}

output "name" {
  description = "The name of the custom domain."
  value       = azapi_resource.custom_domain.name
}

output "resource_id" {
  description = "The resource ID of the custom domain."
  value       = azapi_resource.custom_domain.id
}

output "host_name" {
  description = "The host name of the custom domain."
  value       = jsondecode(azapi_resource.custom_domain.output).properties.hostName
}

output "deployment_status" {
  description = "The deployment status of the custom domain."
  value       = jsondecode(azapi_resource.custom_domain.output).properties.deploymentStatus
}

output "domain_validation_state" {
  description = "The domain validation state of the custom domain."
  value       = jsondecode(azapi_resource.custom_domain.output).properties.domainValidationState
}

output "validation_properties" {
  description = "The validation properties for DNS validation."
  value       = try(jsondecode(azapi_resource.custom_domain.output).properties.validationProperties, null)
}

output "dns_validation" {
  description = "DNS validation information for the custom domain."
  value = {
    dns_txt_record_name = try(
      "_dnsauth.${jsondecode(azapi_resource.custom_domain.output).properties.hostName}",
      null
    )
    dns_txt_record_value = try(
      jsondecode(azapi_resource.custom_domain.output).properties.validationProperties.validationToken,
      null
    )
    dns_txt_record_expiry = try(
      jsondecode(azapi_resource.custom_domain.output).properties.validationProperties.expirationDate,
      null
    )
  }
}
