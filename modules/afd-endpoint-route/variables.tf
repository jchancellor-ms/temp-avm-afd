/*
variable "grpc_state" {
  type        = string
  default     = null
  description = "Whether or not gRPC is enabled on this route. Permitted values are 'Enabled' or 'Disabled'."

  validation {
    condition     = var.grpc_state == null || can(regex("^(Enabled|Disabled)$", var.grpc_state))
    error_message = "grpc_state must be either 'Enabled' or 'Disabled'."
  }
}
*/
variable "afd_endpoint_id" {
  type        = string
  description = <<AFD_ENDPOINT_ID
The full Azure resource ID of the parent AFD endpoint.

Format: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}/afdEndpoints/{endpointName}`

Example Input:

```hcl
afd_endpoint_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/afdEndpoints/my-endpoint"
```
AFD_ENDPOINT_ID
}

variable "afd_endpoint_name" {
  type        = string
  description = <<AFD_ENDPOINT_NAME
The name of the parent AFD endpoint.

This is used for constructing resource references and dependencies.

Example Input:

```hcl
afd_endpoint_name = "my-afd-endpoint"
```
AFD_ENDPOINT_NAME
}

variable "name" {
  type        = string
  description = <<NAME
The name of the AFD endpoint route.

This identifies the specific routing rule within the endpoint.

Example Input:

```hcl
name = "api-route"
```
NAME
}

variable "origin_group_id" {
  type        = string
  description = <<ORIGIN_GROUP_ID
The full Azure resource ID of the origin group to route traffic to.

This defines which backend origin group will handle requests matching this route.

Format: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}/originGroups/{originGroupName}`

Example Input:

```hcl
origin_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/originGroups/my-origin-group"
```
ORIGIN_GROUP_ID
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the parent CDN profile."
}

variable "profile_name" {
  type        = string
  description = "The name of the parent CDN profile."
}

variable "cache_configuration" {
  type = object({
    query_string_caching_behavior = optional(string)
    query_parameters              = optional(string)
    compression_settings = optional(object({
      content_types_to_compress = optional(list(string))
      is_compression_enabled    = optional(bool)
    }))
  })
  default     = null
  description = <<CACHE_CONFIGURATION
Caching configuration for this route.

Controls how content is cached at Azure Front Door edge locations. If not provided, caching will be disabled for this route.

- `query_string_caching_behavior` = (Optional) How to handle query strings when caching. Possible values: `IgnoreQueryString`, `UseQueryString`, `IgnoreSpecifiedQueryStrings`, `IncludeSpecifiedQueryStrings`
- `query_parameters`              = (Optional) Comma-separated list of query parameters to include or exclude from caching
- `compression_settings` = (Optional) Compression configuration
  - `content_types_to_compress` = (Optional) List of MIME types to compress (e.g., `["application/json", "text/html"]`)
  - `is_compression_enabled`    = (Optional) Whether to enable compression

Example Input:

```hcl
cache_configuration = {
  query_string_caching_behavior = "IgnoreQueryString"
  compression_settings = {
    content_types_to_compress = ["application/json", "text/html", "text/css"]
    is_compression_enabled    = true
  }
}
```
CACHE_CONFIGURATION
}

variable "custom_domain_ids" {
  type        = list(string)
  default     = []
  description = <<CUSTOM_DOMAIN_IDS
A list of custom domain Azure resource IDs to associate with this route.

Custom domains allow you to use your own domain names (e.g., `www.example.com`) instead of the default `*.azurefd.net` domain.

Format: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}/customDomains/{domainName}`

Example Input:

```hcl
custom_domain_ids = [
  "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/customDomains/www-example-com",
  "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/customDomains/api-example-com"
]
```
CUSTOM_DOMAIN_IDS
}

variable "enabled_state" {
  type        = string
  default     = "Enabled"
  description = <<ENABLED_STATE
Whether this route is enabled and actively handling traffic.

Possible values:
- `Enabled` - Route is active and will handle matching requests (default)
- `Disabled` - Route is inactive and will not handle requests

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

variable "forwarding_protocol" {
  type        = string
  default     = "MatchRequest"
  description = <<FORWARDING_PROTOCOL
The protocol to use when forwarding traffic from Azure Front Door to the origin servers.

Possible values:
- `HttpOnly` - Always use HTTP when forwarding to origins
- `HttpsOnly` - Always use HTTPS when forwarding to origins
- `MatchRequest` - Use the same protocol as the client request (default)

Example Input:

```hcl
forwarding_protocol = "HttpsOnly"
```
FORWARDING_PROTOCOL

  validation {
    condition     = can(regex("^(HttpOnly|HttpsOnly|MatchRequest)$", var.forwarding_protocol))
    error_message = "forwarding_protocol must be one of: HttpOnly, HttpsOnly, MatchRequest."
  }
}

variable "https_redirect" {
  type        = string
  default     = "Enabled"
  description = <<HTTPS_REDIRECT
Whether to automatically redirect HTTP requests to HTTPS.

When enabled, any HTTP request will receive a redirect response to the equivalent HTTPS URL.

Possible values:
- `Enabled` - Automatically redirect HTTP to HTTPS (default, recommended for security)
- `Disabled` - Allow HTTP requests without redirecting

Example Input:

```hcl
https_redirect = "Enabled"
```
HTTPS_REDIRECT

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.https_redirect))
    error_message = "https_redirect must be either 'Enabled' or 'Disabled'."
  }
}

variable "link_to_default_domain" {
  type        = string
  default     = "Enabled"
  description = <<LINK_TO_DEFAULT_DOMAIN
Whether this route should be accessible via the default `*.azurefd.net` endpoint domain.

Possible values:
- `Enabled` - Route is accessible via both custom domains and the default domain (default)
- `Disabled` - Route is only accessible via custom domains

Example Input:

```hcl
link_to_default_domain = "Disabled"
```
LINK_TO_DEFAULT_DOMAIN

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.link_to_default_domain))
    error_message = "link_to_default_domain must be either 'Enabled' or 'Disabled'."
  }
}

variable "origin_path" {
  type        = string
  default     = null
  description = <<ORIGIN_PATH
A directory path on the origin server that Azure Front Door should prepend to the request path.

This allows you to serve content from a specific subdirectory on the origin without modifying client URLs.

Example Input:

```hcl
origin_path = "/api/v2"
```
ORIGIN_PATH
}

variable "patterns_to_match" {
  type        = list(string)
  default     = null
  description = <<PATTERNS_TO_MATCH
URL path patterns that this route should match and handle.

Supports wildcards (*) for flexible matching. If not specified, the route will not match any requests.

Example Input:

```hcl
patterns_to_match = ["/api/*", "/v1/*", "/v2/*"]
```

For a catch-all route:

```hcl
patterns_to_match = ["/*"]
```
PATTERNS_TO_MATCH
}

variable "rule_set_ids" {
  type        = list(string)
  default     = []
  description = <<RULE_SET_IDS
A list of rule set Azure resource IDs to apply to this route.

Rule sets contain conditional routing rules that can modify request/response headers, perform redirects, rewrites, and more.

Format: `/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}/ruleSets/{ruleSetName}`

Example Input:

```hcl
rule_set_ids = [
  "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/ruleSets/security-rules"
]
```
RULE_SET_IDS
}

variable "supported_protocols" {
  type        = list(string)
  default     = null
  description = <<SUPPORTED_PROTOCOLS
The list of protocols that this route supports.

Possible values:
- `Http` - Allow HTTP requests
- `Https` - Allow HTTPS requests

Typically you would specify both `["Http", "Https"]` and use `https_redirect` to redirect HTTP to HTTPS.

Example Input:

```hcl
supported_protocols = ["Http", "Https"]
```

For HTTPS-only routes:

```hcl
supported_protocols = ["Https"]
```
SUPPORTED_PROTOCOLS

  validation {
    condition = var.supported_protocols == null || alltrue([
      for protocol in var.supported_protocols : can(regex("^(Http|Https)$", protocol))
    ])
    error_message = "supported_protocols must contain only 'Http' or 'Https'."
  }
}
