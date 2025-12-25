variable "name" {
  type        = string
  description = "The name of the origin."
}

variable "profile_name" {
  type        = string
  description = "The name of the parent CDN profile."
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the parent CDN profile."
}

variable "origin_group_name" {
  type        = string
  description = "The name of the origin group."
}

variable "origin_group_id" {
  type        = string
  description = "The resource ID of the origin group."
}

variable "host_name" {
  type        = string
  description = "The address of the origin. Domain names, IPv4 addresses, and IPv6 addresses are supported."
}

variable "azure_origin_id" {
  type        = string
  description = "Resource ID of the Azure origin resource."
  default     = null
}

variable "enabled_state" {
  type        = string
  description = "Whether to enable health probes to be made against backends."
  default     = "Enabled"

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.enabled_state))
    error_message = "enabled_state must be either 'Enabled' or 'Disabled'."
  }
}

variable "enforce_certificate_name_check" {
  type        = bool
  description = "Whether to enable certificate name check at origin level."
  default     = true
}

variable "http_port" {
  type        = number
  description = "The value of the HTTP port. Must be between 1 and 65535."
  default     = 80

  validation {
    condition     = var.http_port >= 1 && var.http_port <= 65535
    error_message = "http_port must be between 1 and 65535."
  }
}

variable "https_port" {
  type        = number
  description = "The value of the HTTPS port. Must be between 1 and 65535."
  default     = 443

  validation {
    condition     = var.https_port >= 1 && var.https_port <= 65535
    error_message = "https_port must be between 1 and 65535."
  }
}

variable "origin_host_header" {
  type        = string
  description = "The host header value sent to the origin with each request."
  default     = null
}

variable "priority" {
  type        = number
  description = "Priority of origin in given origin group for load balancing. Must be between 1 and 5."
  default     = 1

  validation {
    condition     = var.priority >= 1 && var.priority <= 5
    error_message = "priority must be between 1 and 5."
  }
}

variable "weight" {
  type        = number
  description = "Weight of the origin in given origin group for load balancing. Must be between 1 and 1000."
  default     = 1000

  validation {
    condition     = var.weight >= 1 && var.weight <= 1000
    error_message = "weight must be between 1 and 1000."
  }
}

variable "origin_capacity_resource" {
  type = object({
    enabled                        = string
    origin_ingress_rate_threshold  = optional(number)
    origin_request_rate_threshold  = optional(number)
    region                        = optional(string)
  })
  description = "Origin capacity settings for an origin."
  default     = null

  validation {
    condition = var.origin_capacity_resource == null || can(regex("^(Enabled|Disabled)$", var.origin_capacity_resource.enabled))
    error_message = "enabled must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = var.origin_capacity_resource == null || var.origin_capacity_resource.origin_ingress_rate_threshold == null || var.origin_capacity_resource.origin_ingress_rate_threshold >= 1
    error_message = "origin_ingress_rate_threshold must be at least 1."
  }

  validation {
    condition = var.origin_capacity_resource == null || var.origin_capacity_resource.origin_request_rate_threshold == null || var.origin_capacity_resource.origin_request_rate_threshold >= 1
    error_message = "origin_request_rate_threshold must be at least 1."
  }
}

variable "shared_private_link_resource" {
  type = object({
    group_id             = string
    private_link_id      = string
    private_link_location = string
    request_message      = optional(string)
    status               = optional(string)
  })
  description = "The properties of the private link resource for private origin."
  default     = null

  validation {
    condition = var.shared_private_link_resource == null || var.shared_private_link_resource.status == null || can(regex("^(Approved|Disconnected|Pending|Rejected|Timeout)$", var.shared_private_link_resource.status))
    error_message = "status must be one of: Approved, Disconnected, Pending, Rejected, Timeout."
  }
}
