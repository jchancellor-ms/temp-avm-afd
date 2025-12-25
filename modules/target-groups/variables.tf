variable "name" {
  type        = string
  description = "The name of the target group."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+(-*[a-zA-Z0-9])*$", var.name)) && length(var.name) >= 1 && length(var.name) <= 260
    error_message = "The name must be between 1 and 260 characters, contain only alphanumeric characters and hyphens, and cannot start or end with a hyphen."
  }
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the CDN profile."
}

variable "target_endpoints" {
  type = list(object({
    target_fqdn = string
    ports       = list(number)
  }))
  description = "List of target endpoints. Each endpoint includes a target FQDN and list of ports."

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
