variable "associations" {
  type = list(object({
    domains = list(object({
      id = string
    }))
    patterns_to_match = list(string)
  }))
  description = "List of WAF associations. Each association includes domains and URL patterns to match."

  validation {
    condition     = length(var.associations) > 0
    error_message = "At least one association must be specified."
  }
}

variable "name" {
  type        = string
  description = "The name of the security policy."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,260}$", var.name))
    error_message = "The name must be between 1 and 260 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the CDN profile."
}

variable "embedded_waf_policy" {
  type = object({
    etag = optional(string)
    sku = optional(object({
      name = string
    }))
    properties = optional(object({
      custom_rules = optional(object({
        rules = optional(list(object({
          name                           = optional(string)
          priority                       = number
          rule_type                      = string
          action                         = string
          enabled_state                  = optional(string, "Enabled")
          rate_limit_duration_in_minutes = optional(number)
          rate_limit_threshold           = optional(number)
          match_conditions = list(object({
            match_variable   = string
            operator         = string
            match_value      = list(string)
            selector         = optional(string)
            negate_condition = optional(bool, false)
            transforms       = optional(list(string), [])
          }))
          group_by = optional(list(object({
            variable_name = string
          })), [])
        })))
      }))
      managed_rules = optional(object({
        managed_rule_sets = optional(list(object({
          rule_set_type    = string
          rule_set_version = string
          rule_set_action  = optional(string)
          exclusions = optional(list(object({
            match_variable          = string
            selector                = string
            selector_match_operator = string
          })), [])
          rule_group_overrides = optional(list(object({
            rule_group_name = string
            exclusions = optional(list(object({
              match_variable          = string
              selector                = string
              selector_match_operator = string
            })), [])
            rules = optional(list(object({
              rule_id       = string
              enabled_state = optional(string)
              action        = optional(string)
              exclusions = optional(list(object({
                match_variable          = string
                selector                = string
                selector_match_operator = string
              })), [])
            })), [])
          })), [])
        })))
      }))
      policy_settings = optional(object({
        enabled_state                              = optional(string, "Enabled")
        mode                                       = optional(string, "Prevention")
        request_body_check                         = optional(string)
        custom_block_response_status_code          = optional(number)
        custom_block_response_body                 = optional(string)
        redirect_url                               = optional(string)
        captcha_expiration_in_minutes              = optional(number)
        javascript_challenge_expiration_in_minutes = optional(number)
        log_scrubbing = optional(object({
          state = optional(string, "Enabled")
          scrubbing_rules = optional(list(object({
            match_variable          = string
            selector_match_operator = string
            selector                = optional(string)
            state                   = optional(string, "Enabled")
          })), [])
        }))
      }))
    }))
  })
  default     = null
  description = "The embedded WAF policy configuration. Required when type is 'WebApplicationFirewallEmbedded'."
}

variable "type" {
  type        = string
  default     = "WebApplicationFirewall"
  description = "The type of the security policy."

  validation {
    condition     = contains(["WebApplicationFirewall", "WebApplicationFirewallEmbedded"], var.type)
    error_message = "The type must be either 'WebApplicationFirewall' or 'WebApplicationFirewallEmbedded'."
  }
}

variable "waf_policy_resource_id" {
  type        = string
  default     = null
  description = "Resource ID of the WAF policy. Required when type is 'WebApplicationFirewall'."
}
