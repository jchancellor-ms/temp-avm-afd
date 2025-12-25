terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

locals {
  origin_group_properties = merge(
    {
      loadBalancingSettings = {
        additionalLatencyInMilliseconds = var.load_balancing_settings.additional_latency_in_milliseconds
        sampleSize                      = var.load_balancing_settings.sample_size
        successfulSamplesRequired       = var.load_balancing_settings.successful_samples_required
      }
      sessionAffinityState                                  = var.session_affinity_state
      trafficRestorationTimeToHealedOrNewEndpointsInMinutes = var.traffic_restoration_time_to_healed_or_new_endpoints_in_minutes
    },
    var.authentication != null ? {
      authentication = merge(
        {
          scope = var.authentication.scope
          type  = var.authentication.type
        },
        var.authentication.user_assigned_identity_id != null ? {
          userAssignedIdentity = {
            id = var.authentication.user_assigned_identity_id
          }
        } : {}
      )
    } : {},
    var.health_probe_settings != null ? {
      healthProbeSettings = merge(
        var.health_probe_settings.probe_interval_in_seconds != null ? {
          probeIntervalInSeconds = var.health_probe_settings.probe_interval_in_seconds
        } : {},
        var.health_probe_settings.probe_path != null ? {
          probePath = var.health_probe_settings.probe_path
        } : {},
        var.health_probe_settings.probe_protocol != null ? {
          probeProtocol = var.health_probe_settings.probe_protocol
        } : {},
        var.health_probe_settings.probe_request_type != null ? {
          probeRequestType = var.health_probe_settings.probe_request_type
        } : {}
      )
    } : {}
  )
}

# Origin Group Resource
resource "azapi_resource" "origin_group" {
  type      = "Microsoft.Cdn/profiles/originGroups@2025-09-01-preview"
  name      = var.name
  parent_id = var.profile_id

  body = {
    properties = local.origin_group_properties
  }
}

# Origins using the origin-group-origin submodule
module "origin" {
  source = "../origin-group-origin"

  for_each = var.origins

  name              = each.value.name
  profile_name      = var.profile_name
  profile_id        = var.profile_id
  origin_group_name = var.name
  origin_group_id   = azapi_resource.origin_group.id
  host_name         = each.value.host_name

  azure_origin_id                = each.value.azure_origin_id
  enabled_state                  = each.value.enabled_state != null ? each.value.enabled_state : "Enabled"
  enforce_certificate_name_check = each.value.enforce_certificate_name_check != null ? each.value.enforce_certificate_name_check : true
  http_port                      = each.value.http_port != null ? each.value.http_port : 80
  https_port                     = each.value.https_port != null ? each.value.https_port : 443
  origin_host_header             = each.value.origin_host_header
  priority                       = each.value.priority != null ? each.value.priority : 1
  weight                         = each.value.weight != null ? each.value.weight : 1000
  origin_capacity_resource       = each.value.origin_capacity_resource
  shared_private_link_resource   = each.value.shared_private_link_resource
}
