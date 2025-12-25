variable "name" {
  type        = string
  description = "The name of the CDN profile."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+(-*[a-zA-Z0-9])*$", var.name)) && length(var.name) >= 1 && length(var.name) <= 260
    error_message = "The name must be between 1 and 260 characters, contain only alphanumeric characters and hyphens, and cannot start or end with a hyphen."
  }
}

variable "location" {
  type        = string
  description = "The geo-location where the CDN profile resource lives."
  default     = "global"
}

variable "resource_group_id" {
  type        = string
  description = "The resource ID of the resource group where the CDN profile will be deployed."
}

variable "sku_name" {
  type        = string
  description = "The pricing tier (defines Azure Front Door Standard or Premium or a CDN provider, feature list and rate) of the profile."

  validation {
    condition = contains([
      "Classic_AzureFrontDoor",
      "Custom_Verizon",
      "Premium_AzureFrontDoor",
      "Premium_Verizon",
      "StandardPlus_955BandWidth_ChinaCdn",
      "StandardPlus_AvgBandWidth_ChinaCdn",
      "StandardPlus_ChinaCdn",
      "Standard_955BandWidth_ChinaCdn",
      "Standard_Akamai",
      "Standard_AvgBandWidth_ChinaCdn",
      "Standard_AzureFrontDoor",
      "Standard_ChinaCdn",
      "Standard_Microsoft",
      "Standard_Verizon"
    ], var.sku_name)
    error_message = "Invalid SKU name specified."
  }
}

variable "origin_response_timeout_seconds" {
  type        = number
  description = "Send and receive timeout on forwarding request to the origin. When timeout is reached, the request fails and returns."
  default     = 60

  validation {
    condition     = var.origin_response_timeout_seconds >= 16
    error_message = "The origin_response_timeout_seconds must be at least 16."
  }
}

variable "tags" {
  type        = map(string)
  description = "Resource tags for the CDN profile."
  default     = {}
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(list(string), [])
  })
  description = "The managed identity configuration for the CDN profile."
  default     = null
}

variable "log_scrubbing" {
  type = object({
    state = optional(string, "Enabled")
    scrubbing_rules = optional(list(object({
      match_variable          = string
      selector_match_operator = string
      selector                = optional(string)
      state                   = optional(string, "Enabled")
    })), [])
  })
  description = "Defines rules that scrub sensitive fields in the Azure Front Door profile logs."
  default     = null
}

variable "secrets" {
  type = map(object({
    name                      = string
    type                      = optional(string, "AzureFirstPartyManagedCertificate")
    secret_source_resource_id = optional(string)
    secret_version            = optional(string)
    use_latest_version        = optional(bool, false)
    subject_alternative_names = optional(list(string), [])
    key_id                    = optional(string)
  }))
  description = "Map of secrets to create in the CDN profile."
  default     = {}
}

variable "custom_domains" {
  type = map(object({
    name                                    = string
    host_name                               = string
    azure_dns_zone_id                       = optional(string)
    extended_properties                     = optional(map(string))
    pre_validated_custom_domain_resource_id = optional(string)
    tls_settings = optional(object({
      certificate_type            = string
      minimum_tls_version         = optional(string, "TLS12")
      secret_name                 = optional(string)
      cipher_suite_set_type       = optional(string)
      customized_cipher_suite_set = optional(list(string))
    }))
    mtls_settings = optional(object({
      scenario                          = string
      certificate_authority_resource_id = optional(string)
      secret_name                       = optional(string)
      minimum_tls_version               = optional(string, "TLS12")
    }))
  }))
  description = "Map of custom domains to create in the CDN profile."
  default     = {}
}

variable "origin_groups" {
  type = map(object({
    name = string
    load_balancing_settings = object({
      additional_latency_in_milliseconds = optional(number, 50)
      sample_size                        = optional(number, 4)
      successful_samples_required        = optional(number, 3)
    })
    health_probe_settings = optional(object({
      probe_interval_in_seconds = optional(number, 240)
      probe_path                = optional(string, "/")
      probe_protocol            = optional(string, "Http")
      probe_request_type        = optional(string, "HEAD")
    }))
    session_affinity_state                                         = optional(string, "Disabled")
    traffic_restoration_time_to_healed_or_new_endpoints_in_minutes = optional(number, 10)
    authentication = optional(object({
      scope = string
      type  = string
      user_assigned_identity = optional(object({
        resource_id = string
      }))
    }))
    origins = list(object({
      name                           = string
      host_name                      = string
      http_port                      = optional(number, 80)
      https_port                     = optional(number, 443)
      origin_host_header             = optional(string)
      priority                       = optional(number, 1)
      weight                         = optional(number, 1000)
      enabled_state                  = optional(string, "Enabled")
      enforce_certificate_name_check = optional(bool, true)
      origin_capacity_resource = optional(object({
        enabled                       = optional(bool, false)
        origin_ingress_rate_threshold = optional(number)
        origin_request_rate_threshold = optional(number)
        region                        = optional(string)
      }))
      shared_private_link_resource = optional(object({
        group_id              = optional(string)
        private_link_id       = string
        private_link_location = string
        request_message       = optional(string)
        status                = optional(string)
      }))
    }))
  }))
  description = "Map of origin groups to create in the CDN profile."
  default     = {}
}

variable "rule_sets" {
  type = map(object({
    name = string
    rules = optional(list(object({
      name                      = string
      order                     = number
      actions                   = optional(list(map(any)), [])
      conditions                = optional(list(map(any)), [])
      match_processing_behavior = optional(string, "Continue")
    })), [])
  }))
  description = "Map of rule sets to create in the CDN profile."
  default     = {}
}

variable "afd_endpoints" {
  type = map(object({
    name                                   = string
    auto_generated_domain_name_label_scope = optional(string)
    enabled_state                          = optional(string, "Enabled")
    enforce_mtls                           = optional(bool, false)
    routes = optional(list(object({
      name                   = string
      custom_domains         = optional(list(object({ id = string })), [])
      origin_group_id        = string
      origin_path            = optional(string)
      rule_sets              = optional(list(object({ id = string })), [])
      supported_protocols    = optional(list(string), ["Http", "Https"])
      patterns_to_match      = optional(list(string), ["/*"])
      forwarding_protocol    = optional(string, "MatchRequest")
      link_to_default_domain = optional(string, "Enabled")
      https_redirect         = optional(string, "Enabled")
      enabled_state          = optional(string, "Enabled")
      grpc_state             = optional(string, "Disabled")
      cache_configuration = optional(object({
        query_string_caching_behavior = optional(string)
        query_parameters              = optional(string)
        compression_settings = optional(object({
          content_types_to_compress = optional(list(string))
          is_compression_enabled    = optional(string)
        }))
        cache_behavior = optional(string)
        cache_duration = optional(string)
      }))
    })), [])
    tags = optional(map(string))
  }))
  description = "Map of AFD endpoints to create in the CDN profile."
  default     = {}
}

variable "security_policies" {
  type = map(object({
    name                   = string
    type                   = optional(string, "WebApplicationFirewall")
    waf_policy_resource_id = optional(string)
    associations = list(object({
      domains = list(object({
        id = string
      }))
      patterns_to_match = list(string)
    }))
    embedded_waf_policy = optional(object({
      etag = optional(string)
      sku = optional(object({
        name = string
      }))
      properties = optional(object({
        custom_rules = optional(object({
          rules = optional(list(object({
            name                           = optional(string)
            priority                       = number
            rule_type                      = string
            action                         = string
            enabled_state                  = optional(string, "Enabled")
            rate_limit_duration_in_minutes = optional(number)
            rate_limit_threshold           = optional(number)
            match_conditions = list(object({
              match_variable   = string
              operator         = string
              match_value      = list(string)
              selector         = optional(string)
              negate_condition = optional(bool, false)
              transforms       = optional(list(string), [])
            }))
            group_by = optional(list(object({
              variable_name = string
            })), [])
          })))
        }))
        managed_rules = optional(object({
          managed_rule_sets = optional(list(object({
            rule_set_type    = string
            rule_set_version = string
            rule_set_action  = optional(string)
            exclusions = optional(list(object({
              match_variable          = string
              selector                = string
              selector_match_operator = string
            })), [])
            rule_group_overrides = optional(list(object({
              rule_group_name = string
              exclusions = optional(list(object({
                match_variable          = string
                selector                = string
                selector_match_operator = string
              })), [])
              rules = optional(list(object({
                rule_id       = string
                enabled_state = optional(string)
                action        = optional(string)
                exclusions = optional(list(object({
                  match_variable          = string
                  selector                = string
                  selector_match_operator = string
                })), [])
              })), [])
            })), [])
          })))
        }))
        policy_settings = optional(object({
          enabled_state                              = optional(string, "Enabled")
          mode                                       = optional(string, "Prevention")
          request_body_check                         = optional(string)
          custom_block_response_status_code          = optional(number)
          custom_block_response_body                 = optional(string)
          redirect_url                               = optional(string)
          captcha_expiration_in_minutes              = optional(number)
          javascript_challenge_expiration_in_minutes = optional(number)
          log_scrubbing = optional(object({
            state = optional(string, "Enabled")
            scrubbing_rules = optional(list(object({
              match_variable          = string
              selector_match_operator = string
              selector                = optional(string)
              state                   = optional(string, "Enabled")
            })), [])
          }))
        }))
      }))
    }))
  }))
  description = "Map of security policies to create in the CDN profile."
  default     = {}
}

variable "target_groups" {
  type = map(object({
    name = string
    target_endpoints = list(object({
      target_fqdn = string
      ports       = list(number)
    }))
  }))
  description = "Map of target groups to create in the CDN profile."
  default     = {}
}

variable "tunnel_policies" {
  type = map(object({
    name        = string
    tunnel_type = optional(string, "HttpConnect")
    domains = optional(list(object({
      id = string
    })), [])
    target_groups = optional(list(object({
      id = string
    })), [])
  }))
  description = "Map of tunnel policies to create in the CDN profile."
  default     = {}
}

# required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.
DESCRIPTION
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of this resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false
}

# This variable is used to determine if the private_dns_zone_group block should be included,
# or if it is to be managed externally, e.g. using Azure Policy.
# https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault/issues/32
# Alternatively you can use AzAPI, which does not have this issue.
variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
