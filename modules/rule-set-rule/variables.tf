variable "name" {
  type        = string
  description = "The name of the rule."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,259}$", var.name))
    error_message = "The name must be between 1 and 260 characters, start with a letter, and contain only alphanumeric characters."
  }
}

variable "order" {
  type        = number
  description = "The order in which the rules are applied for the endpoint. Possible values {0,1,2,3,…}. A rule with a lesser order will be applied before a rule with a greater order. Rule with order 0 is a special rule. It does not require any condition and actions listed in it will always be applied."

  validation {
    condition     = var.order >= 0
    error_message = "The order must be a non-negative integer."
  }
}

variable "rule_set_id" {
  type        = string
  description = "The resource ID of the rule set."
}

variable "actions" {
  type = list(object({
    name = string
    parameters = optional(object({
      # CacheExpiration action parameters
      cacheBehavior = optional(string)
      cacheDuration = optional(string)
      cacheType     = optional(string)
      # CacheKeyQueryString action parameters
      queryParameters     = optional(string)
      queryStringBehavior = optional(string)
      # Header action parameters
      headerAction = optional(string)
      headerName   = optional(string)
      value        = optional(string)
      # OriginGroupOverride action parameters
      originGroup = optional(object({
        id = optional(string)
      }))
      # RouteConfigurationOverride action parameters
      cacheConfiguration  = optional(any)
      originGroupOverride = optional(any)
      # UrlRedirect action parameters
      customFragment      = optional(string)
      customHostname      = optional(string)
      customPath          = optional(string)
      customQueryString   = optional(string)
      destinationProtocol = optional(string)
      redirectType        = optional(string)
      # UrlRewrite action parameters
      destination           = optional(string)
      preserveUnmatchedPath = optional(bool)
      sourcePattern         = optional(string)
      # UrlSigning action parameters
      algorithm = optional(string)
      parameterNameOverride = optional(list(object({
        paramIndicator = optional(string)
        paramName      = optional(string)
      })))
      # Common parameter
      typeName = optional(string)
    }))
  }))
  default     = []
  description = "A list of actions that are executed when all the conditions of a rule are satisfied."
}

variable "conditions" {
  type = list(object({
    name = string
    parameters = optional(object({
      # Match condition parameters (common to most conditions)
      matchValues     = optional(list(string))
      negateCondition = optional(bool)
      operator        = optional(string)
      selector        = optional(string)
      transforms      = optional(list(string))
      # Common parameter
      typeName = optional(string)
    }))
  }))
  default     = []
  description = "A list of conditions that must be matched for the actions to be executed."
}

variable "match_processing_behavior" {
  type        = string
  default     = "Continue"
  description = "If this rule is a match should the rules engine continue running the remaining rules or stop. If not present, defaults to Continue."

  validation {
    condition     = contains(["Continue", "Stop"], var.match_processing_behavior)
    error_message = "match_processing_behavior must be either 'Continue' or 'Stop'."
  }
}
