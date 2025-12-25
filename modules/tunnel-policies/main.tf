locals {
  tunnel_policy_properties = merge(
    { tunnelType = var.tunnel_type },
    length(var.domains) > 0 ? { domains = var.domains } : {},
    length(var.target_groups) > 0 ? { targetGroups = var.target_groups } : {}
  )
}

resource "azapi_resource" "tunnel_policy" {
  name      = var.name
  parent_id = var.profile_id
  type      = "Microsoft.Cdn/profiles/tunnelPolicies@2024-06-01-preview"
  body = {
    properties = local.tunnel_policy_properties
  }
}
