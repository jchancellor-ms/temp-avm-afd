locals {
  origin_properties = merge(
    {
      hostName                    = var.host_name
      originHostHeader            = coalesce(var.origin_host_header, var.host_name)
      enabledState                = var.enabled_state
      enforceCertificateNameCheck = var.enforce_certificate_name_check
      httpPort                    = var.http_port
      httpsPort                   = var.https_port
      priority                    = var.priority
      weight                      = var.weight
    },
    var.azure_origin_id != null ? {
      azureOrigin = {
        id = var.azure_origin_id
      }
    } : {},
    var.origin_capacity_resource != null ? {
      originCapacityResource = merge(
        {
          enabled = var.origin_capacity_resource.enabled
        },
        var.origin_capacity_resource.origin_ingress_rate_threshold != null ? {
          originIngressRateThreshold = var.origin_capacity_resource.origin_ingress_rate_threshold
        } : {},
        var.origin_capacity_resource.origin_request_rate_threshold != null ? {
          originRequestRateThreshold = var.origin_capacity_resource.origin_request_rate_threshold
        } : {},
        var.origin_capacity_resource.region != null ? {
          region = var.origin_capacity_resource.region
        } : {}
      )
    } : {},
    var.shared_private_link_resource != null ? {
      sharedPrivateLinkResource = merge(
        {
          groupId = var.shared_private_link_resource.group_id
          privateLink = {
            id = var.shared_private_link_resource.private_link_id
          }
          privateLinkLocation = var.shared_private_link_resource.private_link_location
        },
        var.shared_private_link_resource.request_message != null ? {
          requestMessage = var.shared_private_link_resource.request_message
        } : {},
        var.shared_private_link_resource.status != null ? {
          status = var.shared_private_link_resource.status
        } : {}
      )
    } : {}
  )
}

# Origin Resource
resource "azapi_resource" "origin" {
  name      = var.name
  parent_id = var.origin_group_id
  type      = "Microsoft.Cdn/profiles/originGroups/origins@2025-06-01"
  body = {
    properties = local.origin_properties
  }
}
