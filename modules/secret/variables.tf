variable "name" {
  type        = string
  description = "The name of the secret."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,260}$", var.name))
    error_message = "The name must be between 1 and 260 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the CDN profile."
}

variable "key_id" {
  type        = string
  default     = null
  description = "Defines the customer defined key Id. This id will exist in the incoming request to indicate the key used to form the hash. Required for UrlSigningKey type."
}

variable "secret_source_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of the secret source (Azure Key Vault secret or certificate). Required for CustomerCertificate, MtlsCertificateChain, and UrlSigningKey types."

  validation {
    condition = var.secret_source_resource_id == null || can(regex(
      "^/subscriptions/[a-f0-9-]+/resourceGroups/[^/]+/providers/Microsoft\\.KeyVault/vaults/[^/]+/secrets/[^/]+$",
      var.secret_source_resource_id
    ))
    error_message = "The secret_source_resource_id must be a valid Azure Key Vault secret resource ID."
  }
}

variable "secret_version" {
  type        = string
  default     = null
  description = "The version of the secret. Used for CustomerCertificate, MtlsCertificateChain, and UrlSigningKey types."
}

variable "subject_alternative_names" {
  type        = list(string)
  default     = []
  description = "The list of subject alternative names (SANs). Used for AzureFirstPartyManagedCertificate type."
}

variable "type" {
  type        = string
  default     = "AzureFirstPartyManagedCertificate"
  description = "The type of the secret."

  validation {
    condition = contains([
      "AzureFirstPartyManagedCertificate",
      "CustomerCertificate",
      "ManagedCertificate",
      "MtlsCertificateChain",
      "UrlSigningKey"
    ], var.type)
    error_message = "The type must be one of: AzureFirstPartyManagedCertificate, CustomerCertificate, ManagedCertificate, MtlsCertificateChain, UrlSigningKey."
  }
}

variable "use_latest_version" {
  type        = bool
  default     = false
  description = "Whether to use the latest version for the certificate. Used for CustomerCertificate type."
}
