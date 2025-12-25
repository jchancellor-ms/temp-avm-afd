output "id" {
  description = "The ID of the rule set."
  value       = azapi_resource.rule_set.id
}

output "name" {
  description = "The name of the rule set."
  value       = azapi_resource.rule_set.name
}

output "resource_id" {
  description = "The Azure Resource ID of the rule set."
  value       = azapi_resource.rule_set.id
}

output "rule_ids" {
  description = "Map of rule names to their resource IDs."
  value       = { for name, rule in module.rule : name => rule.id }
}

output "rules" {
  description = "Map of rule names to their module outputs."
  value       = module.rule
}
