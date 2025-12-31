locals {
  # Build the parameters object based on the secret type
  parameters = var.type == "AzureFirstPartyManagedCertificate" ? {
    type                    = var.type
    subjectAlternativeNames = length(var.subject_alternative_names) > 0 ? var.subject_alternative_names : null
    } : var.type == "CustomerCertificate" ? {
    type = var.type
    secretSource = {
      id = var.secret_source_resource_id
    }
    secretVersion    = var.secret_version
    useLatestVersion = var.use_latest_version
    } : var.type == "ManagedCertificate" ? {
    type = var.type
    } : var.type == "MtlsCertificateChain" ? {
    type = var.type
    secretSource = {
      id = var.secret_source_resource_id
    }
    secretVersion = var.secret_version
    } : var.type == "UrlSigningKey" ? {
    type  = var.type
    keyId = var.key_id
    secretSource = {
      id = var.secret_source_resource_id
    }
    secretVersion = var.secret_version
  } : null
  # Remove null values from parameters
  parameters_clean = {
    for k, v in local.parameters : k => v if v != null
  }
}

resource "azapi_resource" "secret" {
  name      = var.name
  parent_id = var.profile_id
  type      = "Microsoft.Cdn/profiles/secrets@2025-06-01"
  body = {
    properties = {
      parameters = local.parameters_clean
    }
  }
}
