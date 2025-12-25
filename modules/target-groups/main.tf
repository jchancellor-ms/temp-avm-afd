locals {
  target_endpoints = [
    for endpoint in var.target_endpoints : {
      targetFqdn = endpoint.target_fqdn
      ports      = endpoint.ports
    }
  ]
}

resource "azapi_resource" "target_group" {
  name      = var.name
  parent_id = var.profile_id
  type      = "Microsoft.Cdn/profiles/targetGroups@2024-06-01-preview"
  body = {
    properties = {
      targetEndpoints = local.target_endpoints
    }
  }
}
