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
  type        = list(map(any))
  default     = []
  description = "A list of actions that are executed when all the conditions of a rule are satisfied."
}

variable "conditions" {
  type        = list(map(any))
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
