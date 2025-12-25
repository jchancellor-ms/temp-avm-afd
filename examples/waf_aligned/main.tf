terraform {
  required_version = "~> 1.10"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Dependencies for WAF-aligned deployment
resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.user_assigned_identity.name_unique}waf"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_storage_account" "this" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.this.location
  name                     = "${module.naming.storage_account.name_unique}waf"
  resource_group_name      = azurerm_resource_group.this.name
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.log_analytics_workspace.name_unique}waf"
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
}

resource "azurerm_eventhub_namespace" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.eventhub_namespace.name_unique}waf"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

resource "azurerm_eventhub" "this" {
  name                = "${module.naming.eventhub.name_unique}waf"
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = azurerm_resource_group.this.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "this" {
  name                = "RootManageSharedAccessKey"
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = azurerm_resource_group.this.name
  listen              = true
  send                = true
  manage              = true
}

# WAF-aligned Premium AFD
# This instance deploys the module in alignment with the best-practices of the Azure Well-Architected Framework
module "test" {
  source = "../../"

  # source             = "Azure/avm-res-cdn-profile/azurerm"
  # version            = "~> 0.1.0"

  name                            = "${module.naming.cdn_profile.name_unique}waf"
  location                        = "global"
  resource_group_id               = azurerm_resource_group.this.id
  sku_name                        = "Premium_AzureFrontDoor" # WAF: Premium SKU for advanced security features
  origin_response_timeout_seconds = 60                       # WAF: Reasonable timeout for reliability
  enable_telemetry                = var.enable_telemetry

  # WAF: Reliability - Enable managed identities for secure access
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }

  # WAF: Cost Optimization & Operational Excellence - Comprehensive tagging
  tags = {
    Environment        = "Production"
    Application        = "CDN-WAF-Aligned"
    CostCenter         = "IT-Infrastructure"
    Owner              = "Platform-Team"
    BusinessUnit       = "Digital-Services"
    Criticality        = "High"
    DataClassification = "Internal"
    BackupRequired     = "Yes"
    MonitoringRequired = "Yes"
    "WAF-Pillar"       = "All"
  }

  # WAF: Security - Custom domains with strong TLS configuration
  custom_domains = {
    "primary-domain" = {
      name      = "${module.naming.cdn_profile.name_unique}wafprimary"
      host_name = "${module.naming.cdn_profile.name_unique}wafprimary.example.com"
      tls_settings = {
        certificate_type      = "ManagedCertificate"
        minimum_tls_version   = "TLS12"
        cipher_suite_set_type = "TLS12_2022" # WAF: Security - Strong cipher suites
      }
    }
    "api-domain" = {
      name      = "${module.naming.cdn_profile.name_unique}wafapi"
      host_name = "api${module.naming.cdn_profile.name_unique}waf.example.com"
      tls_settings = {
        certificate_type      = "ManagedCertificate"
        minimum_tls_version   = "TLS13" # WAF: Security - Use latest TLS version
        cipher_suite_set_type = "Customized"
        customized_cipher_suite_set = [
          "TLS_AES_256_GCM_SHA384", # Strong TLS 1.3 cipher
          "TLS_AES_128_GCM_SHA256"  # Performance balance
        ]
      }
    }
  }

  # WAF: Reliability & Performance - Multi-origin setup with health probes
  origin_groups = {
    "api-origin-group" = {
      name = "${module.naming.cdn_profile.name_unique}wafapiog"
      load_balancing_settings = {
        additional_latency_in_milliseconds = 25 # WAF: Performance - Lower latency for APIs
        sample_size                        = 6  # WAF: Reliability - More samples for critical APIs
        successful_samples_required        = 4  # WAF: Reliability - Higher threshold for APIs
      }
      health_probe_settings = {
        probe_path                = "/api/health" # WAF: Reliability - API-specific health check
        probe_protocol            = "Https"       # WAF: Security - Encrypted health checks
        probe_request_type        = "GET"
        probe_interval_in_seconds = 15 # WAF: Reliability - More frequent for APIs
      }
      session_affinity_state                                         = "Disabled"
      traffic_restoration_time_to_healed_or_new_endpoints_in_minutes = 2 # WAF: Reliability - Faster recovery for APIs
      origins = {
        "api-origin-1" = {
          name                           = "${module.naming.cdn_profile.name_unique}wafapiorg1"
          host_name                      = "${azurerm_storage_account.this.name}.blob.core.windows.net"
          origin_host_header             = "www.bing.com" # Should be 'www.bing.com'
          http_port                      = 80
          https_port                     = 443
          priority                       = 1
          weight                         = 100
          enabled_state                  = "Enabled"
          enforce_certificate_name_check = true # WAF: Security - Certificate validation
        }
        "api-origin-2" = {
          name                           = "${module.naming.cdn_profile.name_unique}wafapiorg2"
          host_name                      = "${azurerm_storage_account.this.name}.blob.core.windows.net"
          origin_host_header             = "" # Should have the RP calculate the name
          http_port                      = 80
          https_port                     = 443
          priority                       = 2
          weight                         = 200
          enabled_state                  = "Enabled"
          enforce_certificate_name_check = true # WAF: Security - Certificate validation
        }
        "api-origin-3" = {
          name                           = "${module.naming.cdn_profile.name_unique}wafapiorg3"
          host_name                      = "${azurerm_storage_account.this.name}.blob.core.windows.net"
          http_port                      = 80
          https_port                     = 443
          priority                       = 3
          weight                         = 300
          enabled_state                  = "Enabled"
          enforce_certificate_name_check = true # WAF: Security - Certificate validation
        }
      }
    }
  }

  # WAF: Security & Performance - Comprehensive routing rules
  rule_sets = {
    "security-rules" = {
      name = "${replace(module.naming.cdn_profile.name_unique, "-", "")}wafsecrules"
      rules = {
        "https-redirect" = {
          name                      = "HTTPSRedirectRule"
          order                     = 1
          match_processing_behavior = "Stop" # WAF: Security - Force HTTPS immediately
          conditions = [
            {
              name = "RequestScheme"
              parameters = {
                typeName        = "DeliveryRuleRequestSchemeConditionParameters"
                operator        = "Equal"
                negateCondition = false
                matchValues     = ["HTTP"]
              }
            }
          ]
          actions = [
            {
              name = "UrlRedirect"
              parameters = {
                typeName            = "DeliveryRuleUrlRedirectActionParameters"
                redirectType        = "PermanentRedirect" # WAF: Security - Permanent HTTPS enforcement
                destinationProtocol = "Https"
              }
            }
          ]
        }
        "security-headers" = {
          name                      = "SecurityHeadersRule"
          order                     = 2
          match_processing_behavior = "Continue"
          conditions = [
            {
              name = "RequestScheme"
              parameters = {
                typeName        = "DeliveryRuleRequestSchemeConditionParameters"
                operator        = "Equal"
                negateCondition = false
                matchValues     = ["HTTPS"]
              }
            }
          ]
          actions = [
            {
              name = "ModifyResponseHeader"
              parameters = {
                typeName     = "DeliveryRuleHeaderActionParameters"
                headerAction = "Overwrite"
                headerName   = "Strict-Transport-Security"
                value        = "max-age=31536000; includeSubDomains; preload" # WAF: Security - HSTS
              }
            },
            {
              name = "ModifyResponseHeader"
              parameters = {
                typeName     = "DeliveryRuleHeaderActionParameters"
                headerAction = "Overwrite"
                headerName   = "X-Content-Type-Options"
                value        = "nosniff" # WAF: Security - MIME type sniffing protection
              }
            },
            {
              name = "ModifyResponseHeader"
              parameters = {
                typeName     = "DeliveryRuleHeaderActionParameters"
                headerAction = "Overwrite"
                headerName   = "X-Frame-Options"
                value        = "DENY" # WAF: Security - Clickjacking protection
              }
            },
            {
              name = "ModifyResponseHeader"
              parameters = {
                typeName     = "DeliveryRuleHeaderActionParameters"
                headerAction = "Overwrite"
                headerName   = "X-XSS-Protection"
                value        = "1; mode=block" # WAF: Security - XSS protection
              }
            },
            {
              name = "ModifyResponseHeader"
              parameters = {
                typeName     = "DeliveryRuleHeaderActionParameters"
                headerAction = "Overwrite"
                headerName   = "Referrer-Policy"
                value        = "strict-origin-when-cross-origin" # WAF: Security - Referrer policy
              }
            }
          ]
        }
        "api-rate-limit" = {
          name                      = "APIRateLimitRule"
          order                     = 3
          match_processing_behavior = "Continue"
          conditions = [
            {
              name = "RequestUri"
              parameters = {
                typeName        = "DeliveryRuleRequestUriConditionParameters"
                operator        = "BeginsWith"
                negateCondition = false
                matchValues     = ["/api/"]
                transforms      = ["Lowercase"]
              }
            }
          ]
          actions = [
            {
              name = "ModifyResponseHeader"
              parameters = {
                typeName     = "DeliveryRuleHeaderActionParameters"
                headerAction = "Overwrite"
                headerName   = "X-RateLimit-Limit"
                value        = "1000" # WAF: Reliability - Rate limiting for APIs
              }
            }
          ]
        }
      }
    }
  }

  # WAF: Performance & Reliability - Optimized AFD endpoints
  afd_endpoints = {
    "api-endpoint" = {
      name                                   = "${module.naming.cdn_profile.name_unique}wafapiep"
      auto_generated_domain_name_label_scope = "TenantReuse" # WAF: Cost Optimization - Reuse domains
      enabled_state                          = "Enabled"
      routes = {
        "api-route" = {
          name            = "${module.naming.cdn_profile.name_unique}wafapiroute"
          origin_group_id = module.test.origin_group_ids["api-origin-group"]
          custom_domains = [
            {
              id = module.test.custom_domain_ids["api-domain"]
            }
          ]
          enabled_state          = "Enabled"
          forwarding_protocol    = "HttpsOnly" # WAF: Security - HTTPS only for APIs
          https_redirect         = "Enabled"
          link_to_default_domain = "Disabled" # WAF: Security - Custom domain only for APIs
          patterns_to_match      = ["/api/*", "/v1/*", "/v2/*"]
          supported_protocols    = ["Https"] # WAF: Security - HTTPS only
          cache_configuration = {
            query_string_caching_behavior = "IgnoreSpecifiedQueryStrings" # WAF: Performance - API-specific caching
            query_parameters              = "timestamp,nonce"             # WAF: Performance - Ignore security parameters
            compression_settings = {
              content_types_to_compress = [
                "application/json",
                "application/xml",
                "text/xml"
              ]
              is_compression_enabled = true # WAF: Performance - API response compression
            }
          }
          rule_sets = [
            {
              id = module.test.rule_set_ids["security-rules"]
            }
          ]
        }
      }
    }
  }

  depends_on = [
    azurerm_storage_account.this,
    azurerm_user_assigned_identity.this,
    azurerm_log_analytics_workspace.this,
    azurerm_eventhub.this
  ]
}
