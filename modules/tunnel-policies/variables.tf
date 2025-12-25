variable "name" {
  type        = string
  description = "The name of the tunnel policy."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+(-*[a-zA-Z0-9])*$", var.name)) && length(var.name) >= 1 && length(var.name) <= 260
    error_message = "The name must be between 1 and 260 characters, contain only alphanumeric characters and hyphens, and cannot start or end with a hyphen."
  }
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the CDN profile."
}

variable "domains" {
  type = list(object({
    id = string
  }))
  default     = []
  description = "List of domain resource references. Each domain includes a resource ID."
}

variable "target_groups" {
  type = list(object({
    id = string
  }))
  default     = []
  description = "List of target group resource references. Each target group includes a resource ID."
}

variable "tunnel_type" {
  type        = string
  default     = "HttpConnect"
  description = "Protocol this tunnel will use for allowing traffic to backends."

  validation {
    condition     = var.tunnel_type == "HttpConnect"
    error_message = "The tunnel_type must be 'HttpConnect'."
  }
}
