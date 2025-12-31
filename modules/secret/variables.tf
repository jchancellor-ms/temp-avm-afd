variable "name" {
  type        = string
  description = <<NAME
The name of the secret resource.

Constraints:
- Must be between 1 and 260 characters
- Can only contain alphanumeric characters and hyphens

Example Input:

```hcl
name = "my-custom-certificate"
```
NAME

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,260}$", var.name))
    error_message = "The name must be between 1 and 260 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "profile_id" {
  type        = string
  description = <<PROFILE_ID
The full Azure Resource ID of the CDN profile where this secret will be stored.

This should be in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}`

Example Input:

```hcl
profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile"
```
PROFILE_ID
}

variable "key_id" {
  type        = string
  default     = null
  description = <<KEY_ID
The customer-defined key identifier for URL signing keys.

This ID will appear in incoming requests to indicate which key was used to form the signature hash. Required when `type` is `UrlSigningKey`.

Example Input:

```hcl
key_id = "signing-key-1"
```
KEY_ID
}

variable "secret_source_resource_id" {
  type        = string
  default     = null
  description = <<SECRET_SOURCE_RESOURCE_ID
The full Azure Resource ID of the Azure Key Vault secret or certificate containing the secret value.

Required for the following secret types:
- `CustomerCertificate` - Customer-provided TLS certificate
- `MtlsCertificateChain` - mTLS CA certificate chain
- `UrlSigningKey` - URL signing key

Must be a valid Azure Key Vault secret resource ID in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{vaultName}/secrets/{secretName}`

Example Input:

```hcl
secret_source_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.KeyVault/vaults/my-keyvault/secrets/my-cert"
```
SECRET_SOURCE_RESOURCE_ID

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
  description = <<SECRET_VERSION
The specific version of the Azure Key Vault secret to use.

If not specified, the latest version will be used. Used for:
- `CustomerCertificate`
- `MtlsCertificateChain`
- `UrlSigningKey`

Example Input:

```hcl
secret_version = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
```
SECRET_VERSION
}

variable "subject_alternative_names" {
  type        = list(string)
  default     = []
  description = <<SUBJECT_ALTERNATIVE_NAMES
The list of Subject Alternative Names (SANs) for the certificate.

Used when `type` is `AzureFirstPartyManagedCertificate` to specify additional domain names covered by the certificate.

Example Input:

```hcl
subject_alternative_names = [
  "www.example.com",
  "api.example.com",
  "cdn.example.com"
]
```
SUBJECT_ALTERNATIVE_NAMES
}

variable "type" {
  type        = string
  default     = "AzureFirstPartyManagedCertificate"
  description = <<TYPE
The type of secret to create.

Possible values:
- `AzureFirstPartyManagedCertificate` - Microsoft-managed certificate (default)
- `CustomerCertificate` - Customer-provided certificate from Azure Key Vault
- `ManagedCertificate` - Azure Front Door managed certificate (free)
- `MtlsCertificateChain` - mTLS CA certificate chain from Key Vault
- `UrlSigningKey` - URL signing key from Key Vault for token authentication

Example Input:

```hcl
type = "CustomerCertificate"
```
TYPE

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
  description = <<USE_LATEST_VERSION
Whether to automatically use the latest version of the certificate from Azure Key Vault.

When set to `true`, Azure Front Door will automatically update to use the newest version of the certificate when it changes in Key Vault. This is useful for automatic certificate rotation.

When set to `false`, the specific `secret_version` will be used (or the current latest version at deployment time if `secret_version` is not specified).

Used for `CustomerCertificate` type only.

Example Input:

```hcl
use_latest_version = true
```
USE_LATEST_VERSION
}
