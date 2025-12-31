variable "load_balancing_settings" {
  type = object({
    additional_latency_in_milliseconds = number
    sample_size                        = number
    successful_samples_required        = number
  })
  description = <<LOAD_BALANCING_SETTINGS
Load balancing configuration for distributing traffic across origins within this origin group.

These settings determine how Azure Front Door distributes requests among healthy origins and how it evaluates origin health for load balancing decisions.

- `additional_latency_in_milliseconds` = (Required) Additional latency in milliseconds for probes to fall into the lowest latency bucket. Range: 0-1000.
- `sample_size`                        = (Required) Number of samples to consider for load balancing decisions. Range: 1-255.
- `successful_samples_required`        = (Required) Number of successful samples required to mark an origin as healthy. Range: 1-255.

Example Input:

```hcl
load_balancing_settings = {
  additional_latency_in_milliseconds = 50
  sample_size                        = 4
  successful_samples_required        = 3
}
```
LOAD_BALANCING_SETTINGS
}

variable "name" {
  type        = string
  description = <<NAME
The name of the origin group resource.

This name uniquely identifies the origin group within the CDN profile and is used when referencing the origin group in routes and other configurations.

Example Input:

```hcl
name = "primary-origin-group"
```
NAME
}

variable "profile_id" {
  type        = string
  description = <<PROFILE_ID
The full Azure Resource ID of the CDN profile where this origin group will be created.

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

variable "authentication" {
  type = object({
    scope                     = string
    type                      = string
    user_assigned_identity_id = optional(string)
  })
  default     = null
  description = <<AUTHENTICATION
Authentication configuration for accessing private origins using managed identities.

This enables Azure Front Door to authenticate to origins that require authentication, such as Azure Storage with private endpoints or Azure App Service with authentication enabled.

- `scope`                     = (Required) The authentication scope, typically the origin's application ID URI.
- `type`                      = (Required) The type of managed identity to use. Possible values are `SystemAssignedIdentity` or `UserAssignedIdentity`.
- `user_assigned_identity_id` = (Optional) The resource ID of the user-assigned managed identity. Required when `type` is `UserAssignedIdentity`.

Example Input:

```hcl
authentication = {
  scope = "https://storage.azure.com/"
  type  = "UserAssignedIdentity"
  user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-identity"
}
```
AUTHENTICATION

  validation {
    condition     = var.authentication == null || can(regex("^(SystemAssignedIdentity|UserAssignedIdentity)$", var.authentication.type))
    error_message = "type must be either 'SystemAssignedIdentity' or 'UserAssignedIdentity'."
  }
}

variable "health_probe_settings" {
  type = object({
    probe_interval_in_seconds = optional(number)
    probe_path                = optional(string)
    probe_protocol            = optional(string)
    probe_request_type        = optional(string)
  })
  default     = null
  description = <<HEALTH_PROBE_SETTINGS
Health probe configuration for monitoring the health status of origins in this group.

Health probes are periodic requests sent to origins to determine if they are healthy and can receive traffic. Unhealthy origins are temporarily removed from the load balancing pool.

- `probe_interval_in_seconds` = (Optional) The number of seconds between health probes. Range: 1-255 seconds.
- `probe_path`                = (Optional) The path relative to the origin to use for health probe requests. Defaults to `/`.
- `probe_protocol`            = (Optional) The protocol to use for health probes. Possible values are `Grpc`, `Http`, `Https`, or `NotSet`.
- `probe_request_type`        = (Optional) The HTTP method to use for health probes. Possible values are `GET`, `HEAD`, or `NotSet`.

Example Input:

```hcl
health_probe_settings = {
  probe_interval_in_seconds = 120
  probe_path                = "/health"
  probe_protocol            = "Https"
  probe_request_type        = "GET"
}
```
HEALTH_PROBE_SETTINGS

  validation {
    condition     = var.health_probe_settings == null || var.health_probe_settings.probe_interval_in_seconds == null || (var.health_probe_settings.probe_interval_in_seconds >= 1 && var.health_probe_settings.probe_interval_in_seconds <= 255)
    error_message = "probe_interval_in_seconds must be between 1 and 255."
  }
  validation {
    condition     = var.health_probe_settings == null || var.health_probe_settings.probe_protocol == null || can(regex("^(Grpc|Http|Https|NotSet)$", var.health_probe_settings.probe_protocol))
    error_message = "probe_protocol must be one of: Grpc, Http, Https, NotSet."
  }
  validation {
    condition     = var.health_probe_settings == null || var.health_probe_settings.probe_request_type == null || can(regex("^(GET|HEAD|NotSet)$", var.health_probe_settings.probe_request_type))
    error_message = "probe_request_type must be one of: GET, HEAD, NotSet."
  }
}

variable "origins" {
  type = map(object({
    name                           = string
    host_name                      = string
    azure_origin_id                = optional(string)
    enabled_state                  = optional(string)
    enforce_certificate_name_check = optional(bool)
    http_port                      = optional(number)
    https_port                     = optional(number)
    origin_host_header             = optional(string)
    priority                       = optional(number)
    weight                         = optional(number)
    origin_capacity_resource = optional(object({
      enabled                       = string
      origin_ingress_rate_threshold = optional(number)
      origin_request_rate_threshold = optional(number)
      region                        = optional(string)
    }))
    shared_private_link_resource = optional(object({
      group_id              = string
      private_link_id       = string
      private_link_location = string
      request_message       = optional(string)
      status                = optional(string)
    }))
  }))
  default     = {}
  description = <<ORIGINS
A map of origins (backend servers) to include in this origin group.

Each origin represents a backend server that can handle requests. Multiple origins provide redundancy and enable load balancing.

- `<map key>` - Use a custom map key to define each origin configuration
  - `name`                           = (Required) The name of the origin.
  - `host_name`                      = (Required) The hostname or IP address of the origin server.
  - `azure_origin_id`                = (Optional) The resource ID of an Azure origin (e.g., App Service, Storage Account).
  - `enabled_state`                  = (Optional) Whether this origin is enabled. Possible values are `Enabled` or `Disabled`.
  - `enforce_certificate_name_check` = (Optional) Whether to enforce certificate name validation for HTTPS origins. Defaults to `true`.
  - `http_port`                      = (Optional) The port to use for HTTP traffic. Range: 1-65535.
  - `https_port`                     = (Optional) The port to use for HTTPS traffic. Range: 1-65535.
  - `origin_host_header`             = (Optional) The Host header to send to the origin.
  - `priority`                       = (Optional) The priority of this origin. Lower values have higher priority. Range: 1-5.
  - `weight`                         = (Optional) The weight of this origin for load balancing. Range: 1-1000.
  - `origin_capacity_resource` = (Optional) Origin capacity configuration
    - `enabled`                       = (Required) Whether origin capacity management is enabled.
    - `origin_ingress_rate_threshold` = (Optional) The ingress rate threshold in Mbps.
    - `origin_request_rate_threshold` = (Optional) The request rate threshold in requests per second.
    - `region`                        = (Optional) The Azure region of the origin.
  - `shared_private_link_resource` = (Optional) Private Link configuration for accessing private origins
    - `group_id`              = (Required) The group ID of the private link service.
    - `private_link_id`       = (Required) The resource ID of the private link service.
    - `private_link_location` = (Required) The Azure region of the private link service.
    - `request_message`       = (Optional) A message to include in the private link connection request.
    - `status`                = (Optional) The status of the private link connection.

Example Input:

```hcl
origins = {
  "origin-1" = {
    name               = "primary-backend"
    host_name          = "backend.example.com"
    http_port          = 80
    https_port         = 443
    origin_host_header = "backend.example.com"
    priority           = 1
    weight             = 1000
    enabled_state      = "Enabled"
  }
}
```
ORIGINS
}

variable "session_affinity_state" {
  type        = string
  default     = "Disabled"
  description = <<SESSION_AFFINITY_STATE
Whether to enable session affinity (sticky sessions) for this origin group.

When enabled, requests from the same client will be routed to the same origin server, which is useful for stateful applications.

Possible values:
- `Enabled` - Route requests from the same client to the same origin
- `Disabled` - Distribute requests across all healthy origins (default)

Example Input:

```hcl
session_affinity_state = "Enabled"
```
SESSION_AFFINITY_STATE

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.session_affinity_state))
    error_message = "session_affinity_state must be either 'Enabled' or 'Disabled'."
  }
}

variable "traffic_restoration_time_to_healed_or_new_endpoints_in_minutes" {
  type        = number
  default     = 10
  description = <<TRAFFIC_RESTORATION_TIME
Time in minutes to gradually restore traffic to a previously unhealthy origin that has become healthy again, or to a newly added origin.

This gradual restoration prevents overwhelming a newly healthy or new origin with traffic immediately. Traffic is incrementally increased over this time period.

Constraints:
- Range: 0-50 minutes
- Default: 10 minutes
- Set to 0 to immediately restore full traffic

Example Input:

```hcl
traffic_restoration_time_to_healed_or_new_endpoints_in_minutes = 10
```
TRAFFIC_RESTORATION_TIME

  validation {
    condition     = var.traffic_restoration_time_to_healed_or_new_endpoints_in_minutes >= 0 && var.traffic_restoration_time_to_healed_or_new_endpoints_in_minutes <= 50
    error_message = "traffic_restoration_time_to_healed_or_new_endpoints_in_minutes must be between 0 and 50."
  }
}
