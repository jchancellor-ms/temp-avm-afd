/* #TODO: enable when supported in AFD Endpoint resource
variable "enforce_mtls" {
  type        = string
  default     = "Disabled"
  description = "Set to Disabled by default. If set to Enabled, only custom domains with mTLS enabled can be added to child Route resources."

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.enforce_mtls))
    error_message = "enforce_mtls must be either 'Enabled' or 'Disabled'."
  }
}
*/
variable "name" {
  type        = string
  description = <<NAME
The name of the Azure Front Door (AFD) endpoint.

This will be used as part of the endpoint's auto-generated domain name (e.g., `{name}.azurefd.net`).

Example Input:

```hcl
name = "my-afd-endpoint"
```
NAME
}

variable "profile_id" {
  type        = string
  description = <<PROFILE_ID
The full Azure resource ID of the parent CDN profile.

Format: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}`

Example Input:

```hcl
profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-cdn-profile"
```
PROFILE_ID
}

variable "profile_name" {
  type        = string
  description = <<PROFILE_NAME
The name of the parent CDN profile.

This is used for constructing child resource IDs and references.

Example Input:

```hcl
profile_name = "my-cdn-profile"
```
PROFILE_NAME
}

variable "auto_generated_domain_name_label_scope" {
  type        = string
  default     = "TenantReuse"
  description = <<AUTO_GENERATED_DOMAIN_NAME_LABEL_SCOPE
Specifies the reuse scope for the auto-generated endpoint domain name.

This controls whether the endpoint name can be reused in different scopes:
- `NoReuse` - The endpoint name must be globally unique across all Azure tenants
- `ResourceGroupReuse` - The endpoint name can be reused in different resource groups
- `SubscriptionReuse` - The endpoint name can be reused in different subscriptions
- `TenantReuse` - The endpoint name can be reused in different tenants (default)

Example Input:

```hcl
auto_generated_domain_name_label_scope = "TenantReuse"
```
AUTO_GENERATED_DOMAIN_NAME_LABEL_SCOPE

  validation {
    condition     = can(regex("^(NoReuse|ResourceGroupReuse|SubscriptionReuse|TenantReuse)$", var.auto_generated_domain_name_label_scope))
    error_message = "auto_generated_domain_name_label_scope must be one of: NoReuse, ResourceGroupReuse, SubscriptionReuse, TenantReuse."
  }
}

variable "enabled_state" {
  type        = string
  default     = "Enabled"
  description = <<ENABLED_STATE
Whether the AFD endpoint is enabled and can serve traffic.

Possible values:
- `Enabled` - The endpoint is active and can serve traffic (default)
- `Disabled` - The endpoint is inactive and will not serve traffic

Example Input:

```hcl
enabled_state = "Enabled"
```
ENABLED_STATE

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.enabled_state))
    error_message = "enabled_state must be either 'Enabled' or 'Disabled'."
  }
}

variable "location" {
  type        = string
  default     = "global"
  description = <<LOCATION
The Azure region where the AFD endpoint metadata is stored.

For Azure Front Door endpoints, this should typically be set to `global` as AFD is a globally distributed service.

Example Input:

```hcl
location = "global"
```
LOCATION
}

variable "routes" {
  type = map(object({
    name            = string
    origin_group_id = string
    cache_configuration = optional(object({
      query_string_caching_behavior = optional(string)
      query_parameters              = optional(string)
      compression_settings = optional(object({
        content_types_to_compress = optional(list(string))
        is_compression_enabled    = optional(bool)
      }))
    }))
    custom_domain_ids   = optional(list(string))
    enabled_state       = optional(string)
    forwarding_protocol = optional(string)
    #grpc_state             = optional(string) #TODO: enable when supported in AFD Endpoint resource route resource
    https_redirect         = optional(string)
    link_to_default_domain = optional(string)
    origin_path            = optional(string)
    patterns_to_match      = optional(list(string))
    rule_set_ids           = optional(list(string))
    supported_protocols    = optional(list(string))
  }))
  default     = {}
  description = <<ROUTES
A map of routes to configure for this AFD endpoint.

Routes define how traffic is handled for specific URL patterns, including origin selection, caching behavior, custom domains, and rule sets.

- `<map key>` - Use a custom map key to define each route configuration
  - `name`            = (Required) The name of the route
  - `origin_group_id` = (Required) The Azure resource ID of the origin group to route traffic to
  - `cache_configuration` = (Optional) Cache configuration for this route
    - `query_string_caching_behavior` = (Optional) How to handle query strings in caching
    - `query_parameters`              = (Optional) Query parameters to include/exclude from caching
    - `compression_settings` = (Optional) Compression configuration
      - `content_types_to_compress` = (Optional) List of content types to compress
      - `is_compression_enabled`    = (Optional) Whether compression is enabled
  - `custom_domain_ids`   = (Optional) List of custom domain resource IDs to associate with this route
  - `enabled_state`       = (Optional) Whether the route is enabled
  - `forwarding_protocol` = (Optional) Protocol to use when forwarding to origin
  - `https_redirect`         = (Optional) Whether to redirect HTTP to HTTPS
  - `link_to_default_domain` = (Optional) Whether to link to the default endpoint domain
  - `origin_path`            = (Optional) Path on the origin to retrieve content from
  - `patterns_to_match`      = (Optional) URL patterns this route should handle
  - `rule_set_ids`           = (Optional) List of rule set resource IDs to apply
  - `supported_protocols`    = (Optional) List of supported protocols (Http, Https)

Example Input:

```hcl
routes = {
  "default" = {
    name            = "default-route"
    origin_group_id = "/subscriptions/.../originGroups/my-origin-group"
    patterns_to_match = ["/*"]
  }
}
```
ROUTES
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = <<TAGS
A map of tags to assign to the AFD endpoint resource.

Example Input:

```hcl
tags = {
  Environment = "Production"
  Service     = "WebApp"
}
```
TAGS
}
