variable "name" {
  type        = string
  description = "The name of the AFD Endpoint."
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the parent CDN profile."
}

variable "profile_name" {
  type        = string
  description = "The name of the parent CDN profile."
}

variable "auto_generated_domain_name_label_scope" {
  type        = string
  default     = "TenantReuse"
  description = "Indicates the endpoint name reuse scope. The default value is TenantReuse."

  validation {
    condition     = can(regex("^(NoReuse|ResourceGroupReuse|SubscriptionReuse|TenantReuse)$", var.auto_generated_domain_name_label_scope))
    error_message = "auto_generated_domain_name_label_scope must be one of: NoReuse, ResourceGroupReuse, SubscriptionReuse, TenantReuse."
  }
}

variable "enabled_state" {
  type        = string
  default     = "Enabled"
  description = "Indicates whether the AFD Endpoint is enabled. The default value is Enabled."

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.enabled_state))
    error_message = "enabled_state must be either 'Enabled' or 'Disabled'."
  }
}

variable "enforce_mtls" {
  type        = string
  default     = "Disabled"
  description = "Set to Disabled by default. If set to Enabled, only custom domains with mTLS enabled can be added to child Route resources."

  validation {
    condition     = can(regex("^(Enabled|Disabled)$", var.enforce_mtls))
    error_message = "enforce_mtls must be either 'Enabled' or 'Disabled'."
  }
}

variable "location" {
  type        = string
  default     = "global"
  description = "The location of the AFD Endpoint."
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
    custom_domain_ids      = optional(list(string))
    enabled_state          = optional(string)
    forwarding_protocol    = optional(string)
    grpc_state             = optional(string)
    https_redirect         = optional(string)
    link_to_default_domain = optional(string)
    origin_path            = optional(string)
    patterns_to_match      = optional(list(string))
    rule_set_ids           = optional(list(string))
    supported_protocols    = optional(list(string))
  }))
  default     = {}
  description = "A map of routes for this AFD Endpoint."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "The tags of the AFD Endpoint."
}
