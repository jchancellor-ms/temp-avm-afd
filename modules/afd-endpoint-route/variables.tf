variable "name" {
  type        = string
  description = "The name of the route."
}

variable "profile_name" {
  type        = string
  description = "The name of the parent CDN profile."
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the parent CDN profile."
}

variable "afd_endpoint_name" {
  type        = string
  description = "The name of the AFD endpoint."
}

variable "afd_endpoint_id" {
  type        = string
  description = "The resource ID of the AFD endpoint."
}

variable "origin_group_id" {
  type        = string
  description = "The resource ID of the origin group."
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
  description = "The caching configuration for this route. To disable caching, do not provide a cacheConfiguration object."
  default     = null
}

variable "custom_domain_ids" {
  type        = list(string)
  description = "The resource IDs of the custom domains."
  default     = []
}

variable "enabled_state" {
  type        = string
  description = "Whether to enable use of this rule."
  default     = "Enabled"

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.enabled_state))
    error_message = "enabled_state must be either 'Enabled' or 'Disabled'."
  }
}

variable "forwarding_protocol" {
  type        = string
  description = "The protocol this rule will use when forwarding traffic to backends."
  default     = "MatchRequest"

  validation {
    condition     = can(regex("^(HttpOnly|HttpsOnly|MatchRequest)$", var.forwarding_protocol))
    error_message = "forwarding_protocol must be one of: HttpOnly, HttpsOnly, MatchRequest."
  }
}

variable "grpc_state" {
  type        = string
  description = "Whether or not gRPC is enabled on this route. Permitted values are 'Enabled' or 'Disabled'."
  default     = null

  validation {
    condition     = var.grpc_state == null || can(regex("^(Enabled|Disabled)$", var.grpc_state))
    error_message = "grpc_state must be either 'Enabled' or 'Disabled'."
  }
}

variable "https_redirect" {
  type        = string
  description = "Whether to automatically redirect HTTP traffic to HTTPS traffic."
  default     = "Enabled"

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.https_redirect))
    error_message = "https_redirect must be either 'Enabled' or 'Disabled'."
  }
}

variable "link_to_default_domain" {
  type        = string
  description = "Whether this route will be linked to the default endpoint domain."
  default     = "Enabled"

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.link_to_default_domain))
    error_message = "link_to_default_domain must be either 'Enabled' or 'Disabled'."
  }
}

variable "origin_path" {
  type        = string
  description = "A directory path on the origin that AzureFrontDoor can use to retrieve content from."
  default     = null
}

variable "patterns_to_match" {
  type        = list(string)
  description = "The route patterns of the rule."
  default     = null
}

variable "rule_set_ids" {
  type        = list(string)
  description = "The resource IDs of the rule sets."
  default     = []
}

variable "supported_protocols" {
  type        = list(string)
  description = "The supported protocols of the rule."
  default     = null

  validation {
    condition = var.supported_protocols == null || alltrue([
      for protocol in var.supported_protocols : can(regex("^(Http|Https)$", protocol))
    ])
    error_message = "supported_protocols must contain only 'Http' or 'Https'."
  }
}
