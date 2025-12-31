variable "host_name" {
  type        = string
  description = <<HOST_NAME
The address of the origin server.

This can be a domain name, IPv4 address, or IPv6 address pointing to your backend server.

Examples:
- Domain name: `backend.example.com`
- IPv4 address: `192.0.2.1`
- IPv6 address: `2001:db8::1`

Example Input:

```hcl
host_name = "backend.example.com"
```
HOST_NAME
}

variable "name" {
  type        = string
  description = <<NAME
The name of the origin resource.

This name uniquely identifies the origin within its origin group.

Example Input:

```hcl
name = "primary-backend"
```
NAME
}

variable "origin_group_id" {
  type        = string
  description = <<ORIGIN_GROUP_ID
The full Azure Resource ID of the origin group where this origin will be added.

This should be in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}/originGroups/{originGroupName}`

Example Input:

```hcl
origin_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/originGroups/my-origin-group"
```
ORIGIN_GROUP_ID
}

variable "origin_group_name" {
  type        = string
  description = <<ORIGIN_GROUP_NAME
The name of the parent origin group.

This is used to construct resource references and must match the name in the `origin_group_id`.

Example Input:

```hcl
origin_group_name = "my-origin-group"
```
ORIGIN_GROUP_NAME
}

variable "profile_id" {
  type        = string
  description = <<PROFILE_ID
The full Azure Resource ID of the CDN profile.

This should be in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}`

Example Input:

```hcl
profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile"
```
PROFILE_ID
}

variable "profile_name" {
  type        = string
  description = <<PROFILE_NAME
The name of the parent CDN profile.

This is used to construct resource references and must match the name in the `profile_id`.

Example Input:

```hcl
profile_name = "my-cdn-profile"
```
PROFILE_NAME
}

variable "azure_origin_id" {
  type        = string
  default     = null
  description = <<AZURE_ORIGIN_ID
The full Azure Resource ID of an Azure service to use as the origin.

This is used when your origin is an Azure service such as App Service, Storage Account, or Application Gateway. When specified, Azure Front Door can automatically discover origin properties.

Example Input:

```hcl
azure_origin_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Web/sites/my-app-service"
```
AZURE_ORIGIN_ID
}

variable "enabled_state" {
  type        = string
  default     = "Enabled"
  description = <<ENABLED_STATE
Whether this origin is enabled to receive traffic.

When disabled, the origin will not receive any traffic even if it is healthy.

Possible values:
- `Enabled` - Origin can receive traffic (default)
- `Disabled` - Origin will not receive traffic

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

variable "enforce_certificate_name_check" {
  type        = bool
  default     = true
  description = <<ENFORCE_CERTIFICATE_NAME_CHECK
Whether to validate that the certificate name matches the origin hostname for HTTPS connections.

When enabled, Azure Front Door will verify that the SSL/TLS certificate presented by the origin matches the origin's hostname. This is recommended for production environments to prevent man-in-the-middle attacks.

Set to `false` only for testing environments or when using self-signed certificates.

Example Input:

```hcl
enforce_certificate_name_check = true
```
ENFORCE_CERTIFICATE_NAME_CHECK
}

variable "http_port" {
  type        = number
  default     = 80
  description = <<HTTP_PORT
The TCP port number for HTTP traffic to this origin.

Constraints:
- Range: 1-65535
- Default: 80 (standard HTTP port)

Example Input:

```hcl
http_port = 8080
```
HTTP_PORT

  validation {
    condition     = var.http_port >= 1 && var.http_port <= 65535
    error_message = "http_port must be between 1 and 65535."
  }
}

variable "https_port" {
  type        = number
  default     = 443
  description = <<HTTPS_PORT
The TCP port number for HTTPS traffic to this origin.

Constraints:
- Range: 1-65535
- Default: 443 (standard HTTPS port)

Example Input:

```hcl
https_port = 8443
```
HTTPS_PORT

  validation {
    condition     = var.https_port >= 1 && var.https_port <= 65535
    error_message = "https_port must be between 1 and 65535."
  }
}

variable "origin_capacity_resource" {
  type = object({
    enabled                       = string
    origin_ingress_rate_threshold = optional(number)
    origin_request_rate_threshold = optional(number)
    region                        = optional(string)
  })
  default     = null
  description = <<ORIGIN_CAPACITY_RESOURCE
Origin capacity management configuration for traffic control based on origin load.

This feature helps prevent overwhelming origins by monitoring their capacity and adjusting traffic distribution accordingly.

- `enabled`                       = (Required) Whether origin capacity management is enabled. Possible values are `Enabled` or `Disabled`.
- `origin_ingress_rate_threshold` = (Optional) The ingress rate threshold in Mbps. Must be at least 1 if specified.
- `origin_request_rate_threshold` = (Optional) The request rate threshold in requests per second. Must be at least 1 if specified.
- `region`                        = (Optional) The Azure region of the origin for capacity calculations.

Example Input:

```hcl
origin_capacity_resource = {
  enabled                       = "Enabled"
  origin_ingress_rate_threshold = 1000
  origin_request_rate_threshold = 500
  region                        = "eastus"
}
```
ORIGIN_CAPACITY_RESOURCE

  validation {
    condition     = var.origin_capacity_resource == null || can(regex("^(Enabled|Disabled)$", var.origin_capacity_resource.enabled))
    error_message = "enabled must be either 'Enabled' or 'Disabled'."
  }
  validation {
    condition     = var.origin_capacity_resource == null || var.origin_capacity_resource.origin_ingress_rate_threshold == null || var.origin_capacity_resource.origin_ingress_rate_threshold >= 1
    error_message = "origin_ingress_rate_threshold must be at least 1."
  }
  validation {
    condition     = var.origin_capacity_resource == null || var.origin_capacity_resource.origin_request_rate_threshold == null || var.origin_capacity_resource.origin_request_rate_threshold >= 1
    error_message = "origin_request_rate_threshold must be at least 1."
  }
}

variable "origin_host_header" {
  type        = string
  default     = null
  description = <<ORIGIN_HOST_HEADER
The Host header value to send to the origin with each request.

If not specified, the request hostname will be used. This is useful when the origin requires a specific Host header value that differs from its hostname (e.g., for virtual hosting or origin validation).

Example Input:

```hcl
origin_host_header = "backend.example.com"
```
ORIGIN_HOST_HEADER
}

variable "priority" {
  type        = number
  default     = 1
  description = <<PRIORITY
The priority of this origin for load balancing within its origin group.

Lower values indicate higher priority. Azure Front Door will prefer origins with lower priority values when all origins are healthy.

Constraints:
- Range: 1-5
- Default: 1 (highest priority)
- Lower values = higher priority

Example Input:

```hcl
priority = 1
```
PRIORITY

  validation {
    condition     = var.priority >= 1 && var.priority <= 5
    error_message = "priority must be between 1 and 5."
  }
}

variable "shared_private_link_resource" {
  type = object({
    group_id              = string
    private_link_id       = string
    private_link_location = string
    request_message       = optional(string)
    status                = optional(string)
  })
  default     = null
  description = <<SHARED_PRIVATE_LINK_RESOURCE
Private Link configuration for securely connecting to private origins.

This enables Azure Front Door to connect to origins that are not publicly accessible, using Azure Private Link.

- `group_id`              = (Required) The group ID of the private link service (e.g., `sites`, `blob`, `vault`).
- `private_link_id`       = (Required) The resource ID of the private link service or target resource.
- `private_link_location` = (Required) The Azure region of the private link service.
- `request_message`       = (Optional) A message to include with the private endpoint connection request.
- `status`                = (Optional) The status of the private link connection. Possible values are `Approved`, `Disconnected`, `Pending`, `Rejected`, or `Timeout`.

Example Input:

```hcl
shared_private_link_resource = {
  group_id              = "sites"
  private_link_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Web/sites/my-app-service"
  private_link_location = "eastus"
  request_message       = "Please approve this connection"
  status                = "Approved"
}
```
SHARED_PRIVATE_LINK_RESOURCE

  validation {
    condition     = var.shared_private_link_resource == null || var.shared_private_link_resource.status == null || can(regex("^(Approved|Disconnected|Pending|Rejected|Timeout)$", var.shared_private_link_resource.status))
    error_message = "status must be one of: Approved, Disconnected, Pending, Rejected, Timeout."
  }
}

variable "weight" {
  type        = number
  default     = 1000
  description = <<WEIGHT
The weight of this origin for load balancing within its origin group.

Higher values mean the origin will receive proportionally more traffic. This is used when multiple origins have the same priority.

Constraints:
- Range: 1-1000
- Default: 1000 (maximum weight)
- Higher values = more traffic

For example, with two origins weighted 1000 and 500, the first will receive approximately 2/3 of the traffic.

Example Input:

```hcl
weight = 1000
```
WEIGHT

  validation {
    condition     = var.weight >= 1 && var.weight <= 1000
    error_message = "weight must be between 1 and 1000."
  }
}
