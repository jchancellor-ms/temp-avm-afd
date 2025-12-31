variable "host_name" {
  type        = string
  description = <<HOST_NAME
The fully qualified domain name (FQDN) of the custom domain.

This must be a valid domain name that you own. You will need to create DNS records to validate ownership and route traffic.

Examples:
- `www.example.com`
- `api.example.com`
- `cdn.example.com`

Example Input:

```hcl
host_name = "www.example.com"
```
HOST_NAME
}

variable "name" {
  type        = string
  description = <<NAME
The name of the custom domain resource.

This name uniquely identifies the custom domain within the CDN profile. It is typically derived from the hostname but with special characters replaced.

Example Input:

```hcl
name = "www-example-com"
```
NAME
}

variable "profile_id" {
  type        = string
  description = <<PROFILE_ID
The full Azure Resource ID of the CDN profile where this custom domain will be created.

This should be in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}`

Example Input:

```hcl
profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile"
```
PROFILE_ID
}

variable "profile_name" {
  type        = string
  description = <<PROFILE_NAME
The name of the parent CDN profile.

This is used to construct resource references and must match the name in the `profile_id`.

Example Input:

```hcl
profile_name = "my-cdn-profile"
```
PROFILE_NAME
}

variable "azure_dns_zone_id" {
  type        = string
  default     = null
  description = <<AZURE_DNS_ZONE_ID
The full Azure Resource ID of an Azure DNS zone that contains this domain.

When specified, Azure Front Door can automatically validate domain ownership if you manage DNS through Azure DNS.

Example Input:

```hcl
azure_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/dnsZones/example.com"
```
AZURE_DNS_ZONE_ID
}

variable "extended_properties" {
  type        = map(string)
  default     = null
  description = <<EXTENDED_PROPERTIES
Key-value pairs representing migration or extended properties for this custom domain.

These properties are typically used during domain migrations or for storing custom metadata.

Example Input:

```hcl
extended_properties = {
  migrationSource = "legacy-cdn"
  environment     = "production"
}
```
EXTENDED_PROPERTIES
}

variable "mtls_settings" {
  type = object({
    scenario                     = string
    allowed_fqdns                = optional(list(string))
    certificate_revocation_check = optional(string)
    secret_ids                   = optional(list(string))
  })
  default     = null
  description = <<MTLS_SETTINGS
Mutual TLS (mTLS) configuration for client certificate authentication on this custom domain.

mTLS requires clients to present valid certificates, providing an additional layer of security beyond standard TLS.

- `scenario`                     = (Required) The mTLS scenario. Possible values:
  - `ClientCertificateRequiredAndOriginValidates` - Client cert required, origin validates it
  - `ClientCertificateRequiredAndValidated` - Client cert required, Azure Front Door validates it
  - `ClientCertificateValidatedIfPresented` - Client cert optional but validated if provided
  - `CompleteMtlsPassthroughToOrigin` - Pass client cert to origin without validation
- `allowed_fqdns`                = (Optional) List of allowed client certificate FQDNs.
- `certificate_revocation_check` = (Optional) Whether to check certificate revocation. Possible values are `Enabled` or `Disabled`.
- `secret_ids`                   = (Optional) List of secret IDs containing CA certificates for validation.

Example Input:

```hcl
mtls_settings = {
  scenario                     = "ClientCertificateRequiredAndValidated"
  certificate_revocation_check = "Enabled"
  secret_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/secrets/ca-cert"
  ]
}
```
MTLS_SETTINGS

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
  description = <<PRE_VALIDATED_CUSTOM_DOMAIN_RESOURCE_ID
The full Azure Resource ID of an Azure resource where custom domain ownership was previously validated.

This allows you to skip domain validation when the domain has already been validated through another Azure service (e.g., App Service custom domain).

Example Input:

```hcl
pre_validated_custom_domain_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Web/sites/my-app-service/hostNameBindings/www.example.com"
```
PRE_VALIDATED_CUSTOM_DOMAIN_RESOURCE_ID
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
  description = <<TLS_SETTINGS
TLS/SSL certificate configuration for enabling HTTPS on this custom domain.

This configures the certificate, TLS version, and cipher suites for secure connections.

- `certificate_type`      = (Required) The type of certificate to use. Possible values:
  - `AzureFirstPartyManagedCertificate` - Microsoft-managed certificate (for select Azure services)
  - `CustomerCertificate` - Bring your own certificate from Azure Key Vault
  - `ManagedCertificate` - Azure Front Door managed certificate (free)
- `cipher_suite_set_type` = (Optional) The cipher suite set to use. Possible values:
  - `Customized` - Use custom cipher suites defined in `customized_cipher_suite_set`
  - `TLS10_2019` - TLS 1.0+ cipher suites (legacy, not recommended)
  - `TLS12_2022` - TLS 1.2+ cipher suites (2022 set)
  - `TLS12_2023` - TLS 1.2+ cipher suites (2023 set, recommended)
- `customized_cipher_suite_set` = (Optional) Custom cipher suite configuration when `cipher_suite_set_type` is `Customized`
  - `cipher_suite_set_for_tls12` = (Optional) List of cipher suites for TLS 1.2 connections
  - `cipher_suite_set_for_tls13` = (Optional) List of cipher suites for TLS 1.3 connections
- `minimum_tls_version` = (Optional) The minimum TLS version to accept. Possible values:
  - `TLS10` - TLS 1.0 or later (not recommended)
  - `TLS12` - TLS 1.2 or later (recommended)
  - `TLS13` - TLS 1.3 or later (most secure)
- `secret_id`           = (Optional) The resource ID of the secret containing the certificate. Required when `certificate_type` is `CustomerCertificate`.

Example Input (Managed Certificate):

```hcl
tls_settings = {
  certificate_type      = "ManagedCertificate"
  minimum_tls_version   = "TLS12"
  cipher_suite_set_type = "TLS12_2023"
}
```

Example Input (Customer Certificate):

```hcl
tls_settings = {
  certificate_type      = "CustomerCertificate"
  minimum_tls_version   = "TLS12"
  cipher_suite_set_type = "TLS12_2023"
  secret_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/secrets/my-cert"
}
```
TLS_SETTINGS

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
