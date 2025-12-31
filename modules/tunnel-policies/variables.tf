variable "name" {
  type        = string
  description = <<NAME
The name of the tunnel policy resource.

Tunnel policies enable secure tunneling of traffic from Azure Front Door to backend origins.

Constraints:
- Must be between 1 and 260 characters
- Can only contain alphanumeric characters and hyphens
- Cannot start or end with a hyphen

Example Input:

```hcl
name = "secure-tunnel-policy"
```
NAME

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+(-*[a-zA-Z0-9])*$", var.name)) && length(var.name) >= 1 && length(var.name) <= 260
    error_message = "The name must be between 1 and 260 characters, contain only alphanumeric characters and hyphens, and cannot start or end with a hyphen."
  }
}

variable "profile_id" {
  type        = string
  description = <<PROFILE_ID
The full Azure Resource ID of the CDN profile where this tunnel policy will be created.

This should be in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}`

Example Input:

```hcl
profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile"
```
PROFILE_ID
}

variable "domains" {
  type = list(object({
    id = string
  }))
  default     = []
  description = <<DOMAINS
List of custom domain resource references that this tunnel policy applies to.

Each domain specifies an Azure Front Door custom domain resource ID.

- `id` = (Required) The full Azure Resource ID of the custom domain

Example Input:

```hcl
domains = [
  {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/customDomains/www-example-com"
  }
]
```
DOMAINS
}

variable "target_groups" {
  type = list(object({
    id = string
  }))
  default     = []
  description = <<TARGET_GROUPS
List of target group resource references that define backend endpoints for this tunnel.

Each target group specifies an Azure Front Door target group resource ID containing backend endpoints.

- `id` = (Required) The full Azure Resource ID of the target group

Example Input:

```hcl
target_groups = [
  {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/targetGroups/backend-targets"
  }
]
```
TARGET_GROUPS
}

variable "tunnel_type" {
  type        = string
  default     = "HttpConnect"
  description = <<TUNNEL_TYPE
The tunneling protocol used for forwarding traffic to backend endpoints.

Currently, only HTTP CONNECT tunneling is supported, which enables secure proxy-style connections to backends.

Possible values:
- `HttpConnect` - HTTP CONNECT proxy protocol (default and only supported value)

Example Input:

```hcl
tunnel_type = "HttpConnect"
```
TUNNEL_TYPE

  validation {
    condition     = var.tunnel_type == "HttpConnect"
    error_message = "The tunnel_type must be 'HttpConnect'."
  }
}
