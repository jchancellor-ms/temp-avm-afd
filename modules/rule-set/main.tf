resource "azapi_resource" "rule_set" {
  name      = var.name
  parent_id = var.profile_id
  type      = "Microsoft.Cdn/profiles/ruleSets@2025-09-01-preview"
}

module "rule" {
  source   = "../rule-set-rule"
  for_each = var.rules

  name                      = each.value.name
  order                     = each.value.order
  rule_set_id               = azapi_resource.rule_set.id
  actions                   = lookup(each.value, "actions", [])
  conditions                = lookup(each.value, "conditions", [])
  match_processing_behavior = lookup(each.value, "match_processing_behavior", "Continue")
}
