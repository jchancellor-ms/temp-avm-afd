variable "name" {
  type        = string
  description = <<NAME
The name of the Azure CDN profile resource.

This value must be globally unique across Azure and will be used to identify the CDN profile in the Azure portal and APIs.

Constraints:
- Must be between 1 and 260 characters in length
- Can only contain alphanumeric characters (a-z, A-Z, 0-9) and hyphens (-)
- Cannot start or end with a hyphen
- Hyphens cannot be consecutive

Example Input:

```hcl
name = "my-cdn-profile-prod"
```
NAME

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+(-*[a-zA-Z0-9])*$", var.name)) && length(var.name) >= 1 && length(var.name) <= 260
    error_message = "The name must be between 1 and 260 characters, contain only alphanumeric characters and hyphens, and cannot start or end with a hyphen."
  }
}

variable "resource_group_id" {
  type        = string
  description = <<RESOURCE_GROUP_ID
The full Azure Resource ID of the resource group where the CDN profile will be deployed.

This should be the complete resource ID in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}`

The resource group must already exist before deploying this module.

Example Input:

```hcl
resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group"
```
RESOURCE_GROUP_ID
}

variable "sku_name" {
  type        = string
  description = <<SKU_NAME
The pricing tier (SKU) of the CDN profile. This determines which features are available and the pricing structure.

The SKU defines whether you're using Azure Front Door or a CDN provider, along with the feature set and rate.

Possible values:

Azure Front Door:
- `Standard_AzureFrontDoor` - Azure Front Door Standard tier with core CDN and security features
- `Premium_AzureFrontDoor` - Azure Front Door Premium tier with advanced security features (WAF, Private Link, etc.)
- `Classic_AzureFrontDoor` - Legacy Azure Front Door (not recommended for new deployments)

Microsoft CDN:
- `Standard_Microsoft` - Microsoft CDN Standard tier

Verizon CDN:
- `Standard_Verizon` - Verizon CDN Standard tier
- `Premium_Verizon` - Verizon CDN Premium tier with advanced features
- `Custom_Verizon` - Custom Verizon CDN configuration

Akamai CDN:
- `Standard_Akamai` - Akamai CDN Standard tier

China CDN:
- `Standard_ChinaCdn` - China CDN Standard tier
- `StandardPlus_ChinaCdn` - China CDN Standard Plus tier
- `Standard_955BandWidth_ChinaCdn` - China CDN Standard with 955 bandwidth model
- `StandardPlus_955BandWidth_ChinaCdn` - China CDN Standard Plus with 955 bandwidth model
- `Standard_AvgBandWidth_ChinaCdn` - China CDN Standard with average bandwidth model
- `StandardPlus_AvgBandWidth_ChinaCdn` - China CDN Standard Plus with average bandwidth model

Example Input:

```hcl
sku_name = "Premium_AzureFrontDoor"
```
SKU_NAME

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

variable "afd_endpoints" {
  type = map(object({
    name                                   = string
    auto_generated_domain_name_label_scope = optional(string, "TenantReuse")
    enabled_state                          = optional(string, "Enabled")
    #enforce_mtls                           = optional(string, "Disabled") #TODO: enable when supported in AFD Endpoint resource
    routes = optional(map(object({
      name                   = string
      custom_domain_ids      = optional(list(string), [])
      origin_group_id        = string
      origin_path            = optional(string)
      rule_set_ids           = optional(list(string), [])
      supported_protocols    = optional(list(string), ["Http", "Https"])
      patterns_to_match      = optional(list(string), ["/*"])
      forwarding_protocol    = optional(string, "MatchRequest")
      link_to_default_domain = optional(string, "Enabled")
      https_redirect         = optional(string, "Enabled")
      enabled_state          = optional(string, "Enabled")
      #grpc_state             = optional(string, "Disabled") #TODO: enable when supported in AFD Endpoint route resource
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
    })), {})
    tags = optional(map(string))
  }))
  default     = {}
  description = <<AFD_ENDPOINTS
A map of Azure Front Door (AFD) endpoints to create within the CDN profile. Each endpoint can have multiple routes configured for content delivery.

- `<map key>` - Use a custom map key to define each AFD endpoint configuration
  - `name`                                   = (Required) The name of the AFD endpoint. Changing this forces a new resource to be created.
  - `auto_generated_domain_name_label_scope` = (Optional) Specifies the client affinity scope of the auto-generated domain name. Possible values are `TenantReuse`, `SubscriptionReuse`, `ResourceGroupReuse`, and `NoReuse`. Defaults to `TenantReuse`.
  - `enabled_state`                          = (Optional) Whether to enable this AFD endpoint. Possible values are `Enabled` or `Disabled`. Defaults to `Enabled`.
  - `routes`                                 = (Optional) A map of routes to configure for this endpoint
    - `<map key>` - Use a custom map key to define each route configuration
      - `name`                   = (Required) The name of the route. Changing this forces a new resource to be created.
      - `custom_domain_ids`      = (Optional) A list of custom domain Azure Resource IDs to associate with this route. Defaults to an empty list.
      - `origin_group_id`        = (Required) The Azure Resource ID of the origin group that this route will use.
      - `origin_path`            = (Optional) A directory path on the origin that AFD can use to retrieve content from.
      - `rule_set_ids`           = (Optional) A list of rule set Azure Resource IDs to associate with this route. Defaults to an empty list.
      - `supported_protocols`    = (Optional) The list of supported protocols for this route. Possible values are `Http` and `Https`. Defaults to `["Http", "Https"]`.
      - `patterns_to_match`      = (Optional) The route patterns to match for this route. Defaults to `["/*"]`.
      - `forwarding_protocol`    = (Optional) The protocol to use when forwarding traffic to backends. Possible values are `HttpOnly`, `HttpsOnly`, or `MatchRequest`. Defaults to `MatchRequest`.
      - `link_to_default_domain` = (Optional) Whether this route should be linked to the default endpoint domain. Possible values are `Enabled` or `Disabled`. Defaults to `Enabled`.
      - `https_redirect`         = (Optional) Whether to automatically redirect HTTP traffic to HTTPS. Possible values are `Enabled` or `Disabled`. Defaults to `Enabled`.
      - `enabled_state`          = (Optional) Whether to enable this route. Possible values are `Enabled` or `Disabled`. Defaults to `Enabled`.
      - `cache_configuration`    = (Optional) Cache configuration for this route
        - `query_string_caching_behavior` = (Optional) Defines how the cache handles query strings. Possible values are `IgnoreQueryString`, `UseQueryString`, `IgnoreSpecifiedQueryStrings`, or `IncludeSpecifiedQueryStrings`.
        - `query_parameters`              = (Optional) Query string parameters to include or exclude from caching (comma-separated).
        - `compression_settings`          = (Optional) Compression settings for cached content
          - `content_types_to_compress` = (Optional) List of content types to compress (e.g., `["application/json", "text/html"]`).
          - `is_compression_enabled`    = (Optional) Whether compression is enabled for this route.
        - `cache_behavior` = (Optional) The caching behavior for this route.
        - `cache_duration` = (Optional) The cache duration for this route.
  - `tags` = (Optional) A map of tags to assign to the AFD endpoint resource.

Example Input:

```hcl
afd_endpoints = {
  "primary-endpoint" = {
    name                                   = "my-afd-endpoint"
    auto_generated_domain_name_label_scope = "TenantReuse"
    enabled_state                          = "Enabled"
    routes = {
      "default-route" = {
        name            = "default-route"
        origin_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/originGroups/my-origin-group"
        custom_domain_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/customDomains/my-domain"
        ]
        enabled_state          = "Enabled"
        forwarding_protocol    = "HttpsOnly"
        https_redirect         = "Enabled"
        link_to_default_domain = "Disabled"
        patterns_to_match      = ["/api/*", "/content/*"]
        supported_protocols    = ["Https"]
        cache_configuration = {
          query_string_caching_behavior = "IgnoreQueryString"
          compression_settings = {
            content_types_to_compress = ["application/json", "text/html", "text/css"]
            is_compression_enabled    = "true"
          }
        }
        rule_set_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/ruleSets/my-rule-set"
        ]
      }
    }
    tags = {
      Environment = "Production"
      Application = "WebApp"
    }
  }
}
```
AFD_ENDPOINTS
}

variable "custom_domains" {
  type = map(object({
    name                                    = string
    host_name                               = string
    azure_dns_zone_id                       = optional(string)
    extended_properties                     = optional(map(string))
    pre_validated_custom_domain_resource_id = optional(string)
    tls_settings = optional(object({
      certificate_type      = string
      minimum_tls_version   = optional(string, "TLS12")
      secret_name           = optional(string)
      cipher_suite_set_type = optional(string)
      customized_cipher_suite_set = optional(object({
        cipher_suite_set_for_tls12 = optional(list(string))
        cipher_suite_set_for_tls13 = optional(list(string))
      }))
    }))
    mtls_settings = optional(object({
      scenario                          = string
      certificate_authority_resource_id = optional(string)
      secret_name                       = optional(string)
      minimum_tls_version               = optional(string, "TLS12")
    }))
  }))
  default     = {}
  description = <<CUSTOM_DOMAINS
A map of custom domains to configure for the CDN profile. Custom domains allow you to use your own domain names with the CDN.

- `<map key>` - Use a custom map key to define each custom domain configuration
  - `name`                                    = (Required) The name of the custom domain resource. Changing this forces a new resource to be created.
  - `host_name`                               = (Required) The host name of the custom domain. Must be a valid domain name (e.g., `www.example.com`).
  - `azure_dns_zone_id`                       = (Optional) The resource ID of an Azure DNS zone that contains the domain. Used for automatic validation.
  - `extended_properties`                     = (Optional) A map of extended properties for the custom domain.
  - `pre_validated_custom_domain_resource_id` = (Optional) The resource ID of a pre-validated custom domain to associate with this domain.
  - `tls_settings`                            = (Optional) TLS/SSL certificate configuration for the custom domain
    - `certificate_type`      = (Required) The type of certificate to use. Possible values are `CustomerCertificate` (bring your own certificate) or `ManagedCertificate` (Azure-managed certificate).
    - `minimum_tls_version`   = (Optional) The minimum TLS version required. Possible values are `TLS10`, `TLS12`. Defaults to `TLS12`.
    - `secret_name`           = (Optional) The name of the secret (certificate) in the CDN profile to use. Required when `certificate_type` is `CustomerCertificate`.
    - `cipher_suite_set_type` = (Optional) The type of cipher suite set to use. Possible values are `Default` or `Custom`.
    - `customized_cipher_suite_set` = (Optional) Custom cipher suite configuration when `cipher_suite_set_type` is `Custom`
      - `cipher_suite_set_for_tls12` = (Optional) List of cipher suites to use for TLS 1.2 connections.
      - `cipher_suite_set_for_tls13` = (Optional) List of cipher suites to use for TLS 1.3 connections.
  - `mtls_settings` = (Optional) Mutual TLS (mTLS) configuration for the custom domain
    - `scenario`                          = (Required) The mTLS scenario. Possible values are `DomainBased` or `IPBased`.
    - `certificate_authority_resource_id` = (Optional) The resource ID of the certificate authority to use for client certificate validation.
    - `secret_name`                       = (Optional) The name of the secret containing the CA certificate.
    - `minimum_tls_version`               = (Optional) The minimum TLS version for mTLS. Defaults to `TLS12`.

Example Input:

```hcl
custom_domains = {
  "www-domain" = {
    name      = "www-example-com"
    host_name = "www.example.com"
    tls_settings = {
      certificate_type    = "ManagedCertificate"
      minimum_tls_version = "TLS12"
    }
  }
  "api-domain" = {
    name      = "api-example-com"
    host_name = "api.example.com"
    tls_settings = {
      certificate_type    = "CustomerCertificate"
      secret_name         = "my-custom-cert"
      minimum_tls_version = "TLS12"
    }
  }
}
```
CUSTOM_DOMAINS
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

variable "location" {
  type        = string
  default     = "global"
  description = <<LOCATION
The Azure region where the CDN profile resource metadata will be stored.

For Azure CDN and Azure Front Door profiles, this should typically be set to `global` as these are globally distributed services. The `global` location indicates that the service is not tied to a specific Azure region and will be available worldwide.

For region-specific CDN deployments (e.g., China CDN), you may specify a specific Azure region.

Example Input:

```hcl
location = "global"
```

Or for China regions:

```hcl
location = "chinaeast2"
```
LOCATION
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<LOCK
Controls the Resource Lock configuration for the CDN profile. Resource locks prevent accidental deletion or modification of critical resources.

- `kind` = (Required) The type of lock to apply. Possible values are:
  - `CanNotDelete` - Authorized users can read and modify the resource, but they cannot delete it
  - `ReadOnly` - Authorized users can read the resource, but they cannot delete or update it
- `name` = (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Example Input:

```hcl
lock = {
  kind = "CanNotDelete"
  name = "prevent-deletion"
}
```
LOCK

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
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
  default     = null
  description = <<LOG_SCRUBBING
Defines log scrubbing rules that remove or mask sensitive information from Azure Front Door profile logs before they are stored or analyzed.

Log scrubbing helps protect sensitive data such as passwords, tokens, API keys, or personally identifiable information (PII) from appearing in logs.

- `state` = (Optional) Whether log scrubbing is enabled. Possible values are `Enabled` or `Disabled`. Defaults to `Enabled`.
- `scrubbing_rules` = (Optional) A list of scrubbing rules to apply to the logs. Defaults to an empty list.
  - `match_variable`          = (Required) The variable to match for scrubbing. Possible values include `RequestHeader`, `RequestUri`, `QueryString`, `RequestBody`, etc.
  - `selector_match_operator` = (Required) The operator to use when matching the selector. Possible values are `Equals` or `EqualsAny`.
  - `selector`                = (Optional) The specific selector to match (e.g., header name, query parameter name). If not specified, all instances of the match_variable will be scrubbed.
  - `state`                   = (Optional) Whether this scrubbing rule is enabled. Possible values are `Enabled` or `Disabled`. Defaults to `Enabled`.

Example Input:

```hcl
log_scrubbing = {
  state = "Enabled"
  scrubbing_rules = [
    {
      match_variable          = "RequestHeader"
      selector_match_operator = "Equals"
      selector                = "Authorization"
      state                   = "Enabled"
    },
    {
      match_variable          = "QueryString"
      selector_match_operator = "Equals"
      selector                = "api_key"
      state                   = "Enabled"
    }
  ]
}
```
LOG_SCRUBBING
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
    origins = map(object({
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
  default     = {}
  description = <<ORIGIN_GROUPS
A map of origin groups to create in the CDN profile. Origin groups define a collection of backend origins and the load balancing/health probe settings for them.

- `<map key>` - Use a custom map key to define each origin group configuration
  - `name` = (Required) The name of the origin group. Changing this forces a new resource to be created.
  - `load_balancing_settings` = (Required) Load balancing configuration for distributing traffic across origins
    - `additional_latency_in_milliseconds` = (Optional) The additional latency in milliseconds for probes to fall into the lowest latency bucket. Defaults to `50`.
    - `sample_size`                        = (Optional) The number of samples to consider for load balancing decisions. Defaults to `4`.
    - `successful_samples_required`        = (Optional) The number of successful samples required to mark an origin as healthy. Defaults to `3`.
  - `health_probe_settings` = (Optional) Health probe configuration for monitoring origin health
    - `probe_interval_in_seconds` = (Optional) The number of seconds between health probes. Defaults to `240`.
    - `probe_path`                = (Optional) The path to use for health probe requests. Defaults to `/`.
    - `probe_protocol`            = (Optional) The protocol to use for health probes. Possible values are `Http`, `Https`, or `NotSet`. Defaults to `Http`.
    - `probe_request_type`        = (Optional) The HTTP method to use for health probes. Possible values are `HEAD`, `GET`, or `NotSet`. Defaults to `HEAD`.
  - `session_affinity_state`                                         = (Optional) Whether session affinity is enabled. Possible values are `Enabled` or `Disabled`. Defaults to `Disabled`.
  - `traffic_restoration_time_to_healed_or_new_endpoints_in_minutes` = (Optional) The time in minutes to wait before restoring traffic to a healed origin. Defaults to `10`.
  - `authentication` = (Optional) Authentication configuration for accessing private origins
    - `scope` = (Required) The scope of the authentication.
    - `type`  = (Required) The type of authentication. Possible values are `ManagedIdentity` or `AzureKeyVault`.
    - `user_assigned_identity` = (Optional) User-assigned managed identity configuration
      - `resource_id` = (Required) The resource ID of the user-assigned managed identity.
  - `origins` = (Required) A map of origins (backend servers) within this origin group
    - `<map key>` - Use a custom map key to define each origin configuration
      - `name`                           = (Required) The name of the origin. Changing this forces a new resource to be created.
      - `host_name`                      = (Required) The hostname or IP address of the origin server (e.g., `api.example.com` or `10.0.0.5`).
      - `http_port`                      = (Optional) The port to use for HTTP traffic. Defaults to `80`.
      - `https_port`                     = (Optional) The port to use for HTTPS traffic. Defaults to `443`.
      - `origin_host_header`             = (Optional) The Host header to send to the origin. If not specified, the request hostname will be used.
      - `priority`                       = (Optional) The priority of this origin. Lower values have higher priority. Range: 1-5. Defaults to `1`.
      - `weight`                         = (Optional) The weight of this origin for load balancing. Higher values receive more traffic. Range: 1-1000. Defaults to `1000`.
      - `enabled_state`                  = (Optional) Whether this origin is enabled. Possible values are `Enabled` or `Disabled`. Defaults to `Enabled`.
      - `enforce_certificate_name_check` = (Optional) Whether to enforce certificate name validation for HTTPS origins. Defaults to `true`.
      - `origin_capacity_resource` = (Optional) Origin capacity configuration for traffic management
        - `enabled`                       = (Optional) Whether origin capacity management is enabled. Defaults to `false`.
        - `origin_ingress_rate_threshold` = (Optional) The ingress rate threshold in Mbps.
        - `origin_request_rate_threshold` = (Optional) The request rate threshold in requests per second.
        - `region`                        = (Optional) The Azure region of the origin.
      - `shared_private_link_resource` = (Optional) Private Link configuration for accessing private origins
        - `group_id`              = (Optional) The group ID of the private link service.
        - `private_link_id`       = (Required) The resource ID of the private link service.
        - `private_link_location` = (Required) The Azure region of the private link service.
        - `request_message`       = (Optional) A message to include in the private link connection request.
        - `status`                = (Optional) The status of the private link connection.

Example Input:

```hcl
origin_groups = {
  "primary-origins" = {
    name = "primary-origin-group"
    load_balancing_settings = {
      additional_latency_in_milliseconds = 50
      sample_size                        = 4
      successful_samples_required        = 3
    }
    health_probe_settings = {
      probe_interval_in_seconds = 120
      probe_path                = "/health"
      probe_protocol            = "Https"
      probe_request_type        = "GET"
    }
    session_affinity_state = "Enabled"
    origins = {
      "origin-1" = {
        name               = "primary-origin-1"
        host_name          = "backend1.example.com"
        http_port          = 80
        https_port         = 443
        origin_host_header = "backend1.example.com"
        priority           = 1
        weight             = 1000
        enabled_state      = "Enabled"
      }
      "origin-2" = {
        name               = "primary-origin-2"
        host_name          = "backend2.example.com"
        https_port         = 443
        origin_host_header = "backend2.example.com"
        priority           = 2
        weight             = 500
        enabled_state      = "Enabled"
      }
    }
  }
}
```
ORIGIN_GROUPS
}

variable "origin_response_timeout_seconds" {
  type        = number
  default     = 60
  description = <<ORIGIN_RESPONSE_TIMEOUT_SECONDS
The timeout in seconds for forwarding requests to and receiving responses from the origin servers.

This value determines how long Azure Front Door will wait for a response from an origin before considering the request as failed and returning a timeout error to the client.

When the timeout is reached, the request fails and returns an error. This helps prevent requests from hanging indefinitely when origins are slow or unresponsive.

Constraints:
- Minimum value: 16 seconds
- Default value: 60 seconds
- Recommended range: 30-120 seconds depending on origin response characteristics

Considerations:
- Set higher values for origins with slow processing times or large response payloads
- Set lower values for fast origins to fail quickly and retry
- Consider origin processing time + network latency when setting this value

Example Input:

```hcl
origin_response_timeout_seconds = 120
```
ORIGIN_RESPONSE_TIMEOUT_SECONDS

  validation {
    condition     = var.origin_response_timeout_seconds >= 16
    error_message = "The origin_response_timeout_seconds must be at least 16."
  }
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
  description = <<PRIVATE_ENDPOINTS_MANAGE_DNS_ZONE_GROUP
Controls whether private DNS zone groups should be managed by this module for private endpoints.

When set to `true`, the module will create and manage private DNS zone groups for each private endpoint, automatically registering DNS records for private endpoint connections.

When set to `false`, you must manage private DNS zone groups externally. This is useful when:
- Using Azure Policy to automatically configure DNS zones
- Managing DNS zones in a centralized hub/spoke network architecture
- Using custom DNS solutions or third-party DNS providers
- Implementing DNS zone management through separate infrastructure

Note: The azurerm provider has limitations with private DNS zone group management that can cause issues in certain scenarios. Using the AzAPI provider (as this module does) avoids these limitations.

Example Input:

```hcl
private_endpoints_manage_dns_zone_group = true
```

For Azure Policy-managed DNS:

```hcl
private_endpoints_manage_dns_zone_group = false
```
PRIVATE_ENDPOINTS_MANAGE_DNS_ZONE_GROUP
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

variable "rule_sets" {
  type = map(object({
    name = string
    rules = optional(map(object({
      name  = string
      order = number
      actions = optional(list(object({
        name = string
        parameters = optional(object({
          # CacheExpiration action parameters
          cacheBehavior = optional(string)
          cacheDuration = optional(string)
          cacheType     = optional(string)
          # CacheKeyQueryString action parameters
          queryParameters     = optional(string)
          queryStringBehavior = optional(string)
          # Header action parameters
          headerAction = optional(string)
          headerName   = optional(string)
          value        = optional(string)
          # OriginGroupOverride action parameters
          originGroup = optional(object({
            id = optional(string)
          }))
          # RouteConfigurationOverride action parameters
          cacheConfiguration  = optional(any)
          originGroupOverride = optional(any)
          # UrlRedirect action parameters
          customFragment      = optional(string)
          customHostname      = optional(string)
          customPath          = optional(string)
          customQueryString   = optional(string)
          destinationProtocol = optional(string)
          redirectType        = optional(string)
          # UrlRewrite action parameters
          destination           = optional(string)
          preserveUnmatchedPath = optional(bool)
          sourcePattern         = optional(string)
          # UrlSigning action parameters
          algorithm = optional(string)
          parameterNameOverride = optional(list(object({
            paramIndicator = optional(string)
            paramName      = optional(string)
          })))
          # Common parameter
          typeName = optional(string)
        }))
      })), [])
      conditions = optional(list(object({
        name = string
        parameters = optional(object({
          # Match condition parameters (common to most conditions)
          matchValues     = optional(list(string))
          negateCondition = optional(bool)
          operator        = optional(string)
          selector        = optional(string)
          transforms      = optional(list(string))
          # Common parameter
          typeName = optional(string)
        }))
      })), [])
      match_processing_behavior = optional(string, "Continue")
    })), {})
  }))
  default     = {}
  description = <<RULE_SETS
A map of rule sets to create in the CDN profile. Rule sets contain routing rules that modify request/response behavior based on conditions.

Rule sets allow you to customize how Azure Front Door processes requests through conditional logic and actions such as URL rewrites, redirects, header modifications, caching behavior, and origin group overrides.

- `<map key>` - Use a custom map key to define each rule set configuration
  - `name` = (Required) The name of the rule set. Changing this forces a new resource to be created.
  - `rules` = (Optional) A map of rules to include in this rule set. Defaults to an empty map.
    - `<map key>` - Use a custom map key to define each rule configuration
      - `name`  = (Required) The name of the rule. Changing this forces a new resource to be created.
      - `order` = (Required) The order in which the rule is evaluated (lower values are processed first). Range: 0-1000.
      - `actions` = (Optional) A list of actions to perform when conditions are met. Defaults to an empty list.
        - `name` = (Required) The action type. Possible values are `CacheExpiration`, `CacheKeyQueryString`, `ModifyRequestHeader`, `ModifyResponseHeader`, `OriginGroupOverride`, `RouteConfigurationOverride`, `UrlRedirect`, `UrlRewrite`, `UrlSigning`.
        - `parameters` = (Optional) Action-specific parameters (structure varies by action type)
          - For `CacheExpiration`: `cacheBehavior`, `cacheDuration`, `cacheType`, `typeName`
          - For `CacheKeyQueryString`: `queryParameters`, `queryStringBehavior`, `typeName`
          - For `ModifyRequestHeader`/`ModifyResponseHeader`: `headerAction`, `headerName`, `value`, `typeName`
          - For `OriginGroupOverride`: `originGroup` (with `id`), `typeName`
          - For `RouteConfigurationOverride`: `cacheConfiguration`, `originGroupOverride`, `typeName`
          - For `UrlRedirect`: `customFragment`, `customHostname`, `customPath`, `customQueryString`, `destinationProtocol`, `redirectType`, `typeName`
          - For `UrlRewrite`: `destination`, `preserveUnmatchedPath`, `sourcePattern`, `typeName`
          - For `UrlSigning`: `algorithm`, `parameterNameOverride`, `typeName`
      - `conditions` = (Optional) A list of conditions that must be met for actions to execute. Defaults to an empty list.
        - `name` = (Required) The condition type. Possible values include `RemoteAddress`, `RequestMethod`, `RequestUri`, `QueryString`, `RequestHeader`, `RequestBody`, `RequestScheme`, `UrlPath`, `UrlFileExtension`, `UrlFileName`, `HttpVersion`, `Cookies`, `IsDevice`, `SocketAddress`, `ClientPort`, `ServerPort`, `HostName`, `SslProtocol`.
        - `parameters` = (Optional) Condition-specific parameters
          - `matchValues`     = (Optional) Values to match against.
          - `negateCondition` = (Optional) Whether to negate the condition result. Defaults to `false`.
          - `operator`        = (Optional) The comparison operator (e.g., `Equal`, `Contains`, `BeginsWith`, `EndsWith`, `LessThan`, `GreaterThan`, `RegEx`, `IPMatch`, etc.).
          - `selector`        = (Optional) The specific element to examine (e.g., header name, cookie name, query parameter).
          - `transforms`      = (Optional) Transformations to apply before matching (e.g., `Lowercase`, `Uppercase`, `Trim`, `UrlDecode`, `UrlEncode`, `RemoveNulls`).
          - `typeName`        = (Optional) The parameter type name for the Azure API.
      - `match_processing_behavior` = (Optional) Whether to continue processing additional rules after this rule matches. Possible values are `Continue` or `Stop`. Defaults to `Continue`.

Example Input:

```hcl
rule_sets = {
  "security-rules" = {
    name = "security-rule-set"
    rules = {
      "block-user-agents" = {
        name  = "block-malicious-agents"
        order = 1
        conditions = [
          {
            name = "RequestHeader"
            parameters = {
              selector        = "User-Agent"
              operator        = "Contains"
              matchValues     = ["badbot", "scraper"]
              negateCondition = false
              transforms      = ["Lowercase"]
              typeName        = "DeliveryRuleRequestHeaderConditionParameters"
            }
          }
        ]
        actions = [
          {
            name = "UrlRedirect"
            parameters = {
              redirectType        = "Found"
              destinationProtocol = "Https"
              customHostname      = "blocked.example.com"
              customPath          = "/blocked"
              typeName            = "DeliveryRuleUrlRedirectActionParameters"
            }
          }
        ]
        match_processing_behavior = "Stop"
      }
      "cache-static-content" = {
        name  = "cache-images-videos"
        order = 2
        conditions = [
          {
            name = "UrlFileExtension"
            parameters = {
              operator        = "Equal"
              matchValues     = ["jpg", "png", "gif", "mp4", "webm"]
              negateCondition = false
              transforms      = ["Lowercase"]
              typeName        = "DeliveryRuleUrlFileExtensionMatchConditionParameters"
            }
          }
        ]
        actions = [
          {
            name = "CacheExpiration"
            parameters = {
              cacheBehavior = "Override"
              cacheDuration = "7.00:00:00"
              cacheType     = "All"
              typeName      = "DeliveryRuleCacheExpirationActionParameters"
            }
          }
        ]
        match_processing_behavior = "Continue"
      }
    }
  }
}
```
RULE_SETS
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
  default     = {}
  description = <<SECRETS
A map of secrets (certificates) to create in the CDN profile. Secrets are used for TLS/SSL certificates on custom domains.

Secrets allow you to store and reference certificates for custom domains. You can use Azure-managed certificates or bring your own certificates from Azure Key Vault.

- `<map key>` - Use a custom map key to define each secret configuration
  - `name`                      = (Required) The name of the secret. Changing this forces a new resource to be created.
  - `type`                      = (Optional) The type of secret. Possible values are:
    - `AzureFirstPartyManagedCertificate` - Azure-managed certificate (default)
    - `CustomerCertificate` - Customer-provided certificate from Key Vault
    - `ManagedCertificate` - Azure Front Door managed certificate
    - `UrlSigningKey` - URL signing key for token authentication
  - `secret_source_resource_id` = (Optional) The resource ID of the source for the secret. Required when `type` is `CustomerCertificate` (should be an Azure Key Vault certificate or secret resource ID).
  - `secret_version`            = (Optional) The version of the secret to use. If not specified, the latest version is used.
  - `use_latest_version`        = (Optional) Whether to automatically use the latest version of the secret. Defaults to `false`. When `true`, the secret will automatically update when a new version is available in Key Vault.
  - `subject_alternative_names` = (Optional) A list of subject alternative names (SANs) for the certificate. Used for managed certificates. Defaults to an empty list.
  - `key_id`                    = (Optional) The Key Vault key ID for URL signing keys.

Example Input:

```hcl
secrets = {
  "custom-cert" = {
    name                      = "my-custom-certificate"
    type                      = "CustomerCertificate"
    secret_source_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.KeyVault/vaults/my-keyvault/certificates/my-cert"
    use_latest_version        = true
  }
  "managed-cert" = {
    name                      = "managed-certificate"
    type                      = "ManagedCertificate"
    subject_alternative_names = ["www.example.com", "api.example.com"]
  }
}
```
SECRETS
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
  default     = {}
  description = <<SECURITY_POLICIES
A map of security policies to create in the CDN profile. Security policies associate Web Application Firewall (WAF) rules with domains and routes.

Security policies protect your applications from common web vulnerabilities and attacks such as SQL injection, cross-site scripting (XSS), and DDoS attacks.

- `<map key>` - Use a custom map key to define each security policy configuration
  - `name`                   = (Required) The name of the security policy. Changing this forces a new resource to be created.
  - `type`                   = (Optional) The type of security policy. Currently only `WebApplicationFirewall` is supported. Defaults to `WebApplicationFirewall`.
  - `waf_policy_resource_id` = (Optional) The resource ID of an existing WAF policy to associate. Mutually exclusive with `embedded_waf_policy`.
  - `associations` = (Required) List of domain and route associations for this security policy
    - `domains` = (Required) List of domain resource IDs to protect
      - `id` = (Required) The Azure resource ID of the custom domain or endpoint
    - `patterns_to_match` = (Required) List of URL path patterns to protect (e.g., `["/api/*", "/*"]`)
  - `embedded_waf_policy` = (Optional) An embedded WAF policy configuration. Mutually exclusive with `waf_policy_resource_id`.
    - `etag` = (Optional) The ETag of the policy
    - `sku` = (Optional) SKU configuration
      - `name` = (Required) The SKU name. Must match the CDN profile SKU (e.g., `Premium_AzureFrontDoor`)
    - `properties` = (Optional) WAF policy properties
      - `custom_rules` = (Optional) Custom WAF rules configuration
        - `rules` = (Optional) List of custom rules
          - `name`                           = (Optional) The name of the custom rule
          - `priority`                       = (Required) The priority of the rule (lower values are processed first). Range: 1-1000
          - `rule_type`                      = (Required) The type of rule. Possible values are `MatchRule` or `RateLimitRule`
          - `action`                         = (Required) The action to take. Possible values are `Allow`, `Block`, `Log`, `Redirect`
          - `enabled_state`                  = (Optional) Whether the rule is enabled. Defaults to `Enabled`
          - `rate_limit_duration_in_minutes` = (Optional) The rate limit duration in minutes. Required when `rule_type` is `RateLimitRule`
          - `rate_limit_threshold`           = (Optional) The rate limit threshold. Required when `rule_type` is `RateLimitRule`
          - `match_conditions` = (Required) List of conditions that must be met
            - `match_variable`   = (Required) The variable to match (e.g., `RemoteAddr`, `RequestMethod`, `QueryString`, `RequestUri`, `RequestHeader`, `RequestBody`, `Cookies`)
            - `operator`         = (Required) The comparison operator (e.g., `IPMatch`, `Equal`, `Contains`, `BeginsWith`, `EndsWith`, `GeoMatch`, `RegEx`)
            - `match_value`      = (Required) List of values to match
            - `selector`         = (Optional) The selector (e.g., header name, cookie name)
            - `negate_condition` = (Optional) Whether to negate the condition. Defaults to `false`
            - `transforms`       = (Optional) List of transformations to apply (e.g., `Lowercase`, `Uppercase`, `Trim`, `UrlDecode`, `UrlEncode`, `RemoveNulls`)
          - `group_by` = (Optional) Variables to group by for rate limiting
            - `variable_name` = (Required) The variable name to group by
      - `managed_rules` = (Optional) Managed rule sets configuration (OWASP, Microsoft, bot protection)
        - `managed_rule_sets` = (Optional) List of managed rule sets to enable
          - `rule_set_type`    = (Required) The rule set type. Common values: `Microsoft_DefaultRuleSet`, `Microsoft_BotManagerRuleSet`, `OWASP` (for OWASP Core Rule Set)
          - `rule_set_version` = (Required) The rule set version (e.g., `2.1`, `2.0`, `1.0`)
          - `rule_set_action`  = (Optional) The action for the entire rule set
          - `exclusions` = (Optional) Global exclusions for the rule set
            - `match_variable`          = (Required) The variable to exclude
            - `selector`                = (Required) The selector value
            - `selector_match_operator` = (Required) The match operator (e.g., `Equals`, `Contains`, `StartsWith`, `EndsWith`)
          - `rule_group_overrides` = (Optional) Overrides for specific rule groups
            - `rule_group_name` = (Required) The name of the rule group to override
            - `exclusions` = (Optional) Exclusions specific to this rule group (same structure as above)
            - `rules` = (Optional) Overrides for specific rules within the group
              - `rule_id`       = (Required) The ID of the rule to override
              - `enabled_state` = (Optional) Whether the rule is enabled
              - `action`        = (Optional) The action override for this rule
              - `exclusions` = (Optional) Exclusions specific to this rule (same structure as above)
      - `policy_settings` = (Optional) General WAF policy settings
        - `enabled_state`                              = (Optional) Whether the policy is enabled. Defaults to `Enabled`
        - `mode`                                       = (Optional) The WAF mode. Possible values are `Prevention` (blocks attacks) or `Detection` (logs only). Defaults to `Prevention`
        - `request_body_check`                         = (Optional) Whether to inspect request bodies
        - `custom_block_response_status_code`          = (Optional) Custom HTTP status code to return when blocking (e.g., `403`, `405`)
        - `custom_block_response_body`                 = (Optional) Custom response body when blocking (base64 encoded)
        - `redirect_url`                               = (Optional) URL to redirect to when blocking
        - `captcha_expiration_in_minutes`              = (Optional) CAPTCHA challenge expiration time in minutes
        - `javascript_challenge_expiration_in_minutes` = (Optional) JavaScript challenge expiration time in minutes
        - `log_scrubbing` = (Optional) Log scrubbing configuration to remove sensitive data from WAF logs
          - `state` = (Optional) Whether log scrubbing is enabled. Defaults to `Enabled`
          - `scrubbing_rules` = (Optional) List of scrubbing rules
            - `match_variable`          = (Required) The variable to scrub
            - `selector_match_operator` = (Required) The match operator
            - `selector`                = (Optional) The selector
            - `state`                   = (Optional) Whether this rule is enabled. Defaults to `Enabled`

Example Input:

```hcl
security_policies = {
  "api-protection" = {
    name = "api-waf-policy"
    type = "WebApplicationFirewall"
    associations = [
      {
        domains = [
          {
            id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/customDomains/api-example-com"
          }
        ]
        patterns_to_match = ["/api/*"]
      }
    ]
    embedded_waf_policy = {
      sku = {
        name = "Premium_AzureFrontDoor"
      }
      properties = {
        policy_settings = {
          enabled_state = "Enabled"
          mode          = "Prevention"
        }
        managed_rules = {
          managed_rule_sets = [
            {
              rule_set_type    = "Microsoft_DefaultRuleSet"
              rule_set_version = "2.1"
            },
            {
              rule_set_type    = "Microsoft_BotManagerRuleSet"
              rule_set_version = "1.0"
            }
          ]
        }
        custom_rules = {
          rules = [
            {
              name      = "rate-limit-api"
              priority  = 100
              rule_type = "RateLimitRule"
              action    = "Block"
              rate_limit_duration_in_minutes = 1
              rate_limit_threshold           = 100
              match_conditions = [
                {
                  match_variable = "RequestUri"
                  operator       = "Contains"
                  match_value    = ["/api/"]
                }
              ]
            }
          ]
        }
      }
    }
  }
}
```
SECURITY_POLICIES
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = <<TAGS
A map of tags to assign to the CDN profile resource.

Tags are key-value pairs that help you organize and categorize Azure resources for management, cost tracking, automation, and governance purposes.

All tags applied to the CDN profile will be inherited by default by child resources unless overridden at the child resource level.

Best practices:
- Use consistent tag naming conventions across your organization
- Include tags for cost center, environment, owner, and application
- Consider using Azure Policy to enforce required tags
- Limit tag names to 512 characters and values to 256 characters
- Avoid sensitive information in tag values as they may be visible in billing reports

Example Input:

```hcl
tags = {
  Environment  = "Production"
  CostCenter   = "IT-12345"
  Application  = "WebApp"
  ManagedBy    = "Terraform"
  Owner        = "platform-team@example.com"
  Compliance   = "PCI-DSS"
  DataClass    = "Internal"
}
```
TAGS
}

variable "target_groups" {
  type = map(object({
    name = string
    target_endpoints = list(object({
      target_fqdn = string
      ports       = list(number)
    }))
  }))
  default     = {}
  description = <<TARGET_GROUPS
A map of target groups to create in the CDN profile. Target groups define collections of backend endpoints for tunnel policies.

Target groups are used with tunnel policies to enable HTTP CONNECT proxy functionality through Azure Front Door, allowing secure tunneling of traffic to specific backend endpoints.

- `<map key>` - Use a custom map key to define each target group configuration
  - `name` = (Required) The name of the target group. Changing this forces a new resource to be created.
  - `target_endpoints` = (Required) A list of target endpoints in this group
    - `target_fqdn` = (Required) The fully qualified domain name (FQDN) or IP address of the target endpoint (e.g., `backend.example.com` or `10.0.0.5`)
    - `ports`       = (Required) A list of TCP ports that can be accessed on this target endpoint (e.g., `[443, 8443]`)

Target groups are typically used for scenarios such as:
- Secure tunneling to private backend services
- HTTP CONNECT proxy scenarios
- Corporate network access through Azure Front Door
- Securing connectivity to backend services

Example Input:

```hcl
target_groups = {
  "private-backends" = {
    name = "corporate-backend-group"
    target_endpoints = [
      {
        target_fqdn = "internal-api.corp.example.com"
        ports       = [443, 8443]
      },
      {
        target_fqdn = "internal-db.corp.example.com"
        ports       = [5432, 3306]
      }
    ]
  }
}
```
TARGET_GROUPS
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
  default     = {}
  description = <<TUNNEL_POLICIES
A map of tunnel policies to create in the CDN profile. Tunnel policies enable secure tunneling functionality through Azure Front Door.

Tunnel policies allow HTTP CONNECT proxy functionality, enabling clients to establish secure tunnels through Azure Front Door to backend services. This is useful for scenarios requiring secure access to private resources or corporate networks.

- `<map key>` - Use a custom map key to define each tunnel policy configuration
  - `name`        = (Required) The name of the tunnel policy. Changing this forces a new resource to be created.
  - `tunnel_type` = (Optional) The type of tunnel. Currently only `HttpConnect` is supported. Defaults to `HttpConnect`.
  - `domains` = (Optional) A list of custom domain or endpoint resource IDs that this tunnel policy applies to. Defaults to an empty list.
    - `id` = (Required) The Azure resource ID of the custom domain or AFD endpoint
  - `target_groups` = (Optional) A list of target group resource IDs that define allowed backend destinations. Defaults to an empty list.
    - `id` = (Required) The Azure resource ID of the target group

Tunnel policies enable use cases such as:
- Secure access to private corporate networks through Azure Front Door
- HTTP CONNECT proxy functionality for controlled backend access
- Tunneling traffic to specific backend services or regions
- Providing secure remote access to internal resources

Example Input:

```hcl
tunnel_policies = {
  "corporate-tunnel" = {
    name        = "secure-corporate-tunnel"
    tunnel_type = "HttpConnect"
    domains = [
      {
        id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/customDomains/tunnel-example-com"
      }
    ]
    target_groups = [
      {
        id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/targetGroups/corporate-backends"
      }
    ]
  }
}
```
TUNNEL_POLICIES
}
