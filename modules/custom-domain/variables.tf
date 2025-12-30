variable "host_name" {
  type        = string
  description = "The host name of the domain. Must be a domain name."
}

variable "name" {
  type        = string
  description = "The name of the custom domain."
}

variable "profile_id" {
  type        = string
  description = "The resource ID of the parent CDN profile."
}

variable "profile_name" {
  type        = string
  description = "The name of the parent CDN profile."
}

variable "azure_dns_zone_id" {
  type        = string
  default     = null
  description = "Resource ID of the Azure DNS zone."
}

variable "extended_properties" {
  type        = map(string)
  default     = null
  description = "Key-Value pair representing migration properties for domains."
}

variable "mtls_settings" {
  type = object({
    scenario                     = string
    allowed_fqdns                = optional(list(string))
    certificate_revocation_check = optional(string)
    secret_ids                   = optional(list(string))
  })
  default     = null
  description = "The configuration specifying how to enable mutual TLS for the domain."

  validation {
    condition     = var.mtls_settings == null || can(regex("^(ClientCertificateRequiredAndOriginValidates|ClientCertificateRequiredAndValidated|ClientCertificateValidatedIfPresented|CompleteMtlsPassthroughToOrigin)$", var.mtls_settings.scenario))
    error_message = "scenario must be one of: ClientCertificateRequiredAndOriginValidates, ClientCertificateRequiredAndValidated, ClientCertificateValidatedIfPresented, CompleteMtlsPassthroughToOrigin."
  }
  validation {
    condition     = var.mtls_settings == null || var.mtls_settings.certificate_revocation_check == null || can(regex("^(Enabled|Disabled)$", var.mtls_settings.certificate_revocation_check))
    error_message = "certificate_revocation_check must be either 'Enabled' or 'Disabled'."
  }
}

variable "pre_validated_custom_domain_resource_id" {
  type        = string
  default     = null
  description = "Resource ID of the Azure resource where custom domain ownership was prevalidated."
}

variable "tls_settings" {
  type = object({
    certificate_type      = string
    cipher_suite_set_type = optional(string)
    customized_cipher_suite_set = optional(object({
      cipher_suite_set_for_tls12 = optional(list(string))
      cipher_suite_set_for_tls13 = optional(list(string))
    }))
    minimum_tls_version = optional(string)
    secret_id           = optional(string)
  })
  default     = null
  description = "The configuration specifying how to enable HTTPS for the domain."

  validation {
    condition     = var.tls_settings == null || can(regex("^(AzureFirstPartyManagedCertificate|CustomerCertificate|ManagedCertificate)$", var.tls_settings.certificate_type))
    error_message = "certificate_type must be one of: AzureFirstPartyManagedCertificate, CustomerCertificate, ManagedCertificate."
  }
  validation {
    condition     = var.tls_settings == null || var.tls_settings.cipher_suite_set_type == null || can(regex("^(Customized|TLS10_2019|TLS12_2022|TLS12_2023)$", var.tls_settings.cipher_suite_set_type))
    error_message = "cipher_suite_set_type must be one of: Customized, TLS10_2019, TLS12_2022, TLS12_2023."
  }
  validation {
    condition     = var.tls_settings == null || var.tls_settings.minimum_tls_version == null || can(regex("^(TLS10|TLS12|TLS13)$", var.tls_settings.minimum_tls_version))
    error_message = "minimum_tls_version must be one of: TLS10, TLS12, TLS13."
  }
}
