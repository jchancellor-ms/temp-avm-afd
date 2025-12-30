locals {
  # Build the properties object
  custom_domain_properties = merge(
    {
      hostName = var.host_name
    },
    var.azure_dns_zone_id != null ? {
      azureDnsZone = {
        id = var.azure_dns_zone_id
      }
    } : {},
    var.extended_properties != null ? {
      extendedProperties = var.extended_properties
    } : {},
    var.pre_validated_custom_domain_resource_id != null ? {
      preValidatedCustomDomainResourceId = {
        id = var.pre_validated_custom_domain_resource_id
      }
    } : {},
    local.tls_settings != null ? {
      tlsSettings = local.tls_settings
    } : {},
    local.mtls_settings != null ? {
      mtlsSettings = local.mtls_settings
    } : {}
  )
  # Build mTLS settings object based on scenario
  mtls_settings = var.mtls_settings != null ? merge(
    {
      scenario = var.mtls_settings.scenario
    },
    # Only include allowedFqdns, certificateRevocationCheck, and secrets for specific scenarios
    contains([
      "ClientCertificateRequiredAndValidated",
      "ClientCertificateValidatedIfPresented"
      ], var.mtls_settings.scenario) ? merge(
      var.mtls_settings.allowed_fqdns != null ? {
        allowedFqdns = var.mtls_settings.allowed_fqdns
      } : {},
      var.mtls_settings.certificate_revocation_check != null ? {
        certificateRevocationCheck = var.mtls_settings.certificate_revocation_check
      } : {},
      var.mtls_settings.secret_ids != null ? {
        secrets = [
          for id in var.mtls_settings.secret_ids : {
            id = id
          }
        ]
      } : {}
    ) : {}
  ) : null
  # Build TLS settings object
  tls_settings = var.tls_settings != null ? merge(
    {
      certificateType = var.tls_settings.certificate_type
    },
    var.tls_settings.cipher_suite_set_type != null ? {
      cipherSuiteSetType = var.tls_settings.cipher_suite_set_type
    } : {},
    var.tls_settings.customized_cipher_suite_set != null ? {
      customizedCipherSuiteSet = merge(
        var.tls_settings.customized_cipher_suite_set.cipher_suite_set_for_tls12 != null ? {
          cipherSuiteSetForTls12 = var.tls_settings.customized_cipher_suite_set.cipher_suite_set_for_tls12
        } : {},
        var.tls_settings.customized_cipher_suite_set.cipher_suite_set_for_tls13 != null ? {
          cipherSuiteSetForTls13 = var.tls_settings.customized_cipher_suite_set.cipher_suite_set_for_tls13
        } : {}
      )
    } : {},
    var.tls_settings.minimum_tls_version != null ? {
      minimumTlsVersion = var.tls_settings.minimum_tls_version
    } : {},
    var.tls_settings.secret_id != null ? {
      secret = {
        id = var.tls_settings.secret_id
      }
    } : {}
  ) : null
}

# Custom Domain Resource
resource "azapi_resource" "custom_domain" {
  name      = var.name
  parent_id = var.profile_id
  type      = "Microsoft.Cdn/profiles/customDomains@2025-09-01-preview"
  body = {
    properties = local.custom_domain_properties
  }
}
