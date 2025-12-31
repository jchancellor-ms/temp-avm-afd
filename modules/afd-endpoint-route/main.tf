locals {
  route_properties = merge(
    {
      originGroup = {
        id = var.origin_group_id
      }
      forwardingProtocol  = var.forwarding_protocol
      httpsRedirect       = var.https_redirect
      linkToDefaultDomain = var.link_to_default_domain
    },
    #var.grpc_state != null ? { #TODO: enable when supported in AFD Endpoint resource
    #  grpcState = var.grpc_state
    #} : {},
    var.cache_configuration != null ? {
      cacheConfiguration = {
        queryStringCachingBehavior = var.cache_configuration.query_string_caching_behavior
        queryParameters            = var.cache_configuration.query_parameters
        compressionSettings = var.cache_configuration.compression_settings != null ? {
          contentTypesToCompress = var.cache_configuration.compression_settings.content_types_to_compress
          isCompressionEnabled   = var.cache_configuration.compression_settings.is_compression_enabled
        } : null
      }
    } : {},
    length(var.custom_domain_ids) > 0 ? {
      customDomains = [
        for id in var.custom_domain_ids : {
          id = id
        }
      ]
    } : {},
    var.enabled_state != null ? {
      enabledState = var.enabled_state
    } : {},
    var.origin_path != null ? {
      originPath = var.origin_path
    } : {},
    var.patterns_to_match != null ? {
      patternsToMatch = var.patterns_to_match
    } : {},
    length(var.rule_set_ids) > 0 ? {
      ruleSets = [
        for id in var.rule_set_ids : {
          id = id
        }
      ]
    } : {},
    var.supported_protocols != null ? {
      supportedProtocols = var.supported_protocols
    } : {}
  )
}

# AFD Endpoint Route Resource
resource "azapi_resource" "route" {
  name      = var.name
  parent_id = var.afd_endpoint_id
  type      = "Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01"
  body = {
    properties = local.route_properties
  }
}
