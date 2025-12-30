variable "load_balancing_settings" {
  type = object({
    additional_latency_in_milliseconds = number
    sample_size                        = number
    successful_samples_required        = number
  })
  description = "Load balancing settings for a backend pool."
}

variable "name" {
  type        = string
  description = "The name of the origin group."
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the parent CDN profile."
}

variable "profile_name" {
  type        = string
  description = "The name of the parent CDN profile."
}

variable "authentication" {
  type = object({
    scope                     = string
    type                      = string
    user_assigned_identity_id = optional(string)
  })
  default     = null
  description = "Authentication settings for origin in origin group."

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
  description = "Health probe settings to the origin that is used to determine the health of the origin."

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
  description = "A map of origins within the origin group."
}

variable "session_affinity_state" {
  type        = string
  default     = "Disabled"
  description = "Whether to allow session affinity on this host."

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.session_affinity_state))
    error_message = "session_affinity_state must be either 'Enabled' or 'Disabled'."
  }
}

variable "traffic_restoration_time_to_healed_or_new_endpoints_in_minutes" {
  type        = number
  default     = 10
  description = "Time in minutes to shift the traffic to the endpoint gradually when an unhealthy endpoint comes healthy or a new endpoint is added."

  validation {
    condition     = var.traffic_restoration_time_to_healed_or_new_endpoints_in_minutes >= 0 && var.traffic_restoration_time_to_healed_or_new_endpoints_in_minutes <= 50
    error_message = "traffic_restoration_time_to_healed_or_new_endpoints_in_minutes must be between 0 and 50."
  }
}
