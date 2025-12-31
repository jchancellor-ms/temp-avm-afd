variable "name" {
  type        = string
  description = <<NAME
The name of the target group resource.

Target groups define backend endpoints for tunnel policies.

Constraints:
- Must be between 1 and 260 characters
- Can only contain alphanumeric characters and hyphens
- Cannot start or end with a hyphen

Example Input:

```hcl
name = "backend-targets"
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
The full Azure Resource ID of the CDN profile where this target group will be created.

This should be in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}`

Example Input:

```hcl
profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile"
```
PROFILE_ID
}

variable "target_endpoints" {
  type = list(object({
    target_fqdn = string
    ports       = list(number)
  }))
  description = <<TARGET_ENDPOINTS
List of target backend endpoints that comprise this target group.

Each endpoint specifies a backend server and the ports it listens on.

- `target_fqdn` = (Required) The fully qualified domain name or IP address of the backend endpoint
- `ports`       = (Required) List of TCP port numbers the backend listens on. Range: 1-65535

Constraints:
- At least one target endpoint must be specified
- Each endpoint must have at least one port
- All ports must be between 1 and 65535

Example Input:

```hcl
target_endpoints = [
  {
    target_fqdn = "backend1.example.com"
    ports       = [443, 8443]
  },
  {
    target_fqdn = "backend2.example.com"
    ports       = [443]
  }
]
```
TARGET_ENDPOINTS

  validation {
    condition     = length(var.target_endpoints) > 0
    error_message = "At least one target endpoint must be specified."
  }
  validation {
    condition = alltrue(flatten([
      for endpoint in var.target_endpoints : [
        for port in endpoint.ports : port >= 1 && port <= 65535
      ]
    ]))
    error_message = "All ports must be between 1 and 65535."
  }
  validation {
    condition = alltrue([
      for endpoint in var.target_endpoints : length(endpoint.ports) > 0
    ])
    error_message = "Each target endpoint must have at least one port specified."
  }
}
