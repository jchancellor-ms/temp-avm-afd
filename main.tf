locals {
  identity = var.managed_identities != null ? {
    type = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : (
      var.managed_identities.system_assigned ? "SystemAssigned" : (
        length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "None"
      )
    )
    identity_ids = length(var.managed_identities.user_assigned_resource_ids) > 0 ? var.managed_identities.user_assigned_resource_ids : null
  } : null
  profile_properties = merge(
    var.origin_response_timeout_seconds != null ? { originResponseTimeoutSeconds = var.origin_response_timeout_seconds } : {},
    var.log_scrubbing != null ? {
      logScrubbing = merge(
        var.log_scrubbing.state != null ? { state = var.log_scrubbing.state } : {},
        length(var.log_scrubbing.scrubbing_rules) > 0 ? {
          scrubbingRules = [
            for rule in var.log_scrubbing.scrubbing_rules : merge(
              { matchVariable = rule.match_variable },
              { selectorMatchOperator = rule.selector_match_operator },
              rule.selector != null ? { selector = rule.selector } : {},
              rule.state != null ? { state = rule.state } : {}
            )
          ]
        } : {}
      )
    } : {}
  )
}

resource "azapi_resource" "profile" {
  location  = var.location
  name      = var.name
  parent_id = var.resource_group_id
  type      = "Microsoft.Cdn/profiles@2025-06-01"
  body = {
    sku = {
      name = var.sku_name
    }
    properties = local.profile_properties
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = local.identity != null ? [local.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  timeouts {
    delete = "1h"
  }
}

# Secrets
module "secret" {
  source   = "./modules/secret"
  for_each = var.secrets

  name                      = each.value.name
  profile_id                = azapi_resource.profile.id
  key_id                    = each.value.key_id
  secret_source_resource_id = each.value.secret_source_resource_id
  secret_version            = each.value.secret_version
  subject_alternative_names = each.value.subject_alternative_names
  type                      = each.value.type
  use_latest_version        = each.value.use_latest_version
}

# Custom Domains
module "custom_domain" {
  source   = "./modules/custom-domain"
  for_each = var.custom_domains

  host_name                               = each.value.host_name
  name                                    = each.value.name
  profile_id                              = azapi_resource.profile.id
  profile_name                            = azapi_resource.profile.name
  azure_dns_zone_id                       = each.value.azure_dns_zone_id
  extended_properties                     = each.value.extended_properties
  mtls_settings                           = each.value.mtls_settings
  pre_validated_custom_domain_resource_id = each.value.pre_validated_custom_domain_resource_id
  tls_settings                            = each.value.tls_settings

  depends_on = [module.secret]
}

# Origin Groups
module "origin_group" {
  source   = "./modules/origin-group"
  for_each = var.origin_groups

  load_balancing_settings                                        = each.value.load_balancing_settings
  name                                                           = each.value.name
  profile_id                                                     = azapi_resource.profile.id
  profile_name                                                   = azapi_resource.profile.name
  authentication                                                 = each.value.authentication
  health_probe_settings                                          = each.value.health_probe_settings
  origins                                                        = each.value.origins
  session_affinity_state                                         = each.value.session_affinity_state
  traffic_restoration_time_to_healed_or_new_endpoints_in_minutes = each.value.traffic_restoration_time_to_healed_or_new_endpoints_in_minutes
}

# Rule Sets
module "rule_set" {
  source   = "./modules/rule-set"
  for_each = var.rule_sets

  name       = each.value.name
  profile_id = azapi_resource.profile.id
  rules      = each.value.rules

  depends_on = [module.origin_group]
}

# AFD Endpoints
module "afd_endpoint" {
  source   = "./modules/afd-endpoint"
  for_each = var.afd_endpoints

  name                                   = each.value.name
  profile_id                             = azapi_resource.profile.id
  profile_name                           = azapi_resource.profile.name
  auto_generated_domain_name_label_scope = each.value.auto_generated_domain_name_label_scope
  enabled_state                          = each.value.enabled_state
  #enforce_mtls                           = each.value.enforce_mtls #TODO: enable when supported in AFD Endpoint resource
  location = var.location
  routes   = each.value.routes
  tags     = each.value.tags

  depends_on = [
    module.origin_group,
    module.custom_domain,
    module.rule_set
  ]
}

# Security Policies
module "security_policy" {
  source   = "./modules/security-policy"
  for_each = var.security_policies

  associations           = each.value.associations
  name                   = each.value.name
  profile_id             = azapi_resource.profile.id
  embedded_waf_policy    = each.value.embedded_waf_policy
  type                   = each.value.type
  waf_policy_resource_id = each.value.waf_policy_resource_id

  depends_on = [
    module.afd_endpoint,
    module.custom_domain
  ]
}

# Target Groups
module "target_group" {
  source   = "./modules/target-groups"
  for_each = var.target_groups

  name             = each.value.name
  profile_id       = azapi_resource.profile.id
  target_endpoints = each.value.target_endpoints
}

# Tunnel Policies
module "tunnel_policy" {
  source   = "./modules/tunnel-policies"
  for_each = var.tunnel_policies

  name          = each.value.name
  profile_id    = azapi_resource.profile.id
  domains       = each.value.domains
  target_groups = each.value.target_groups
  tunnel_type   = each.value.tunnel_type

  depends_on = [
    module.custom_domain,
    module.target_group
  ]
}
