output "id" {
  description = "The ID of the CDN profile."
  value       = azapi_resource.profile.id
}

output "name" {
  description = "The name of the CDN profile."
  value       = azapi_resource.profile.name
}

output "resource_id" {
  description = "The Azure Resource ID of the CDN profile."
  value       = azapi_resource.profile.id
}

output "location" {
  description = "The location of the CDN profile."
  value       = var.location
}

output "secrets" {
  description = "Map of secret names to their module outputs."
  value       = module.secret
}

output "secret_ids" {
  description = "Map of secret names to their resource IDs."
  value       = { for name, secret in module.secret : name => secret.id }
}

output "custom_domains" {
  description = "Map of custom domain names to their module outputs."
  value       = module.custom_domain
}

output "custom_domain_ids" {
  description = "Map of custom domain names to their resource IDs."
  value       = { for name, domain in module.custom_domain : name => domain.id }
}

output "origin_groups" {
  description = "Map of origin group names to their module outputs."
  value       = module.origin_group
}

output "origin_group_ids" {
  description = "Map of origin group names to their resource IDs."
  value       = { for name, og in module.origin_group : name => og.id }
}

output "rule_sets" {
  description = "Map of rule set names to their module outputs."
  value       = module.rule_set
}

output "rule_set_ids" {
  description = "Map of rule set names to their resource IDs."
  value       = { for name, rs in module.rule_set : name => rs.id }
}

output "afd_endpoints" {
  description = "Map of AFD endpoint names to their module outputs."
  value       = module.afd_endpoint
}

output "afd_endpoint_ids" {
  description = "Map of AFD endpoint names to their resource IDs."
  value       = { for name, ep in module.afd_endpoint : name => ep.id }
}

output "afd_endpoint_host_names" {
  description = "Map of AFD endpoint names to their host names."
  value       = { for name, ep in module.afd_endpoint : name => ep.host_name }
}

output "security_policies" {
  description = "Map of security policy names to their module outputs."
  value       = module.security_policy
}

output "security_policy_ids" {
  description = "Map of security policy names to their resource IDs."
  value       = { for name, sp in module.security_policy : name => sp.id }
}

output "target_groups" {
  description = "Map of target group names to their module outputs."
  value       = module.target_group
}

output "target_group_ids" {
  description = "Map of target group names to their resource IDs."
  value       = { for name, tg in module.target_group : name => tg.id }
}

output "tunnel_policies" {
  description = "Map of tunnel policy names to their module outputs."
  value       = module.tunnel_policy
}

output "tunnel_policy_ids" {
  description = "Map of tunnel policy names to their resource IDs."
  value       = { for name, tp in module.tunnel_policy : name => tp.id }
}

