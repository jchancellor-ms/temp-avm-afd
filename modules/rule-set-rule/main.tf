locals {
  rule_properties = merge(
    {
      order = var.order
    },
    length(var.actions) > 0 ? { actions = var.actions } : {},
    length(var.conditions) > 0 ? { conditions = var.conditions } : {},
    var.match_processing_behavior != null ? { matchProcessingBehavior = var.match_processing_behavior } : {}
  )
}

resource "azapi_resource" "rule" {
  name      = var.name
  parent_id = var.rule_set_id
  type      = "Microsoft.Cdn/profiles/ruleSets/rules@2025-09-01-preview"
  body = {
    properties = local.rule_properties
  }
}
