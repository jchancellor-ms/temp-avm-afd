variable "name" {
  type        = string
  description = "The name of the rule set."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,259}$", var.name))
    error_message = "The name must be between 1 and 260 characters, start with a letter, and contain only alphanumeric characters."
  }
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the CDN profile."
}

variable "rules" {
  type = map(object({
    name                      = string
    order                     = number
    actions                   = optional(list(map(any)), [])
    conditions                = optional(list(map(any)), [])
    match_processing_behavior = optional(string, "Continue")
  }))
  default     = {}
  description = "A map of rules to apply to the rule set. Each rule contains conditions and actions."

  validation {
    condition     = alltrue([for k, r in var.rules : r.order >= 0])
    error_message = "Rule order must be a non-negative integer."
  }
  validation {
    condition     = alltrue([for k, r in var.rules : can(regex("^[a-zA-Z][a-zA-Z0-9]{0,259}$", r.name))])
    error_message = "Rule names must be between 1 and 260 characters, start with a letter, and contain only alphanumeric characters."
  }
  validation {
    condition = alltrue([
      for k, r in var.rules :
      r.match_processing_behavior == null || contains(["Continue", "Stop"], r.match_processing_behavior)
    ])
    error_message = "match_processing_behavior must be either 'Continue' or 'Stop'."
  }
}
