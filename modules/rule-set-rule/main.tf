locals {
  # Filter out null values from action parameters
  cleaned_actions = [
    for action in var.actions : {
      name = action.name
      parameters = action.parameters != null ? {
        for k, v in action.parameters : k => v
        if v != null && (
          !can(tolist(v)) || (can(tolist(v)) && length(v) > 0)
        )
      } : null
    } if action.parameters != null
  ]
  # Filter out null values from condition parameters
  cleaned_conditions = [
    for condition in var.conditions : {
      name = condition.name
      parameters = condition.parameters != null ? {
        for k, v in condition.parameters : k => v
        if v != null && (
          !can(tolist(v)) || (can(tolist(v)) && length(v) > 0)
        )
      } : null
    } if condition.parameters != null
  ]
  rule_properties = merge(
    {
      order = var.order
    },
    length(local.cleaned_actions) > 0 ? { actions = local.cleaned_actions } : {},
    length(local.cleaned_conditions) > 0 ? { conditions = local.cleaned_conditions } : {},
    var.match_processing_behavior != null ? { matchProcessingBehavior = var.match_processing_behavior } : {}
  )
}

resource "azapi_resource" "rule" {
  name      = var.name
  parent_id = var.rule_set_id
  type      = "Microsoft.Cdn/profiles/ruleSets/rules@2025-04-15"
  body = {
    properties = local.rule_properties
  }
}
