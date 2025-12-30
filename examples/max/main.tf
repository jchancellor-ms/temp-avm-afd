terraform {
  required_version = "~> 1.10"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
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

# Dependencies
resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_storage_account" "this" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.this.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.this.name
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_eventhub_namespace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.eventhub_namespace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

resource "azurerm_eventhub" "this" {
  message_retention   = 1
  name                = module.naming.eventhub.name_unique
  partition_count     = 2
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_eventhub_namespace_authorization_rule" "this" {
  name                = "RootManageSharedAccessKey"
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = azurerm_resource_group.this.name
  listen              = true
  manage              = true
  send                = true
}

# This is the module call - Using maximum parameter set
# This instance deploys the module with all available features and parameters for Premium_AzureFrontDoor SKU
module "test" {
  source = "../../"

  name              = "${module.naming.cdn_profile.name_unique}max"
  resource_group_id = azurerm_resource_group.this.id
  sku_name          = "Premium_AzureFrontDoor"
  # AFD Endpoints with routes and cache configuration
  afd_endpoints = {
    "endpoint-01" = {
      name          = "${module.naming.cdn_profile.name_unique}afdep"
      enabled_state = "Enabled"
      routes = {
        "route-01" = {
          name            = "${module.naming.cdn_profile.name_unique}route1"
          origin_group_id = module.test.origin_group_ids["origin-group-01"]
          custom_domains = [
            {
              id = module.test.custom_domain_ids["custom-domain-01"]
            }
          ]
          enabled_state          = "Enabled"
          forwarding_protocol    = "MatchRequest"
          https_redirect         = "Enabled"
          link_to_default_domain = "Enabled"
          patterns_to_match      = ["/api/*", "/health"]
          supported_protocols    = ["Http", "Https"]
          cache_configuration = {
            query_string_caching_behavior = "IncludeSpecifiedQueryStrings"
            query_parameters              = "version,locale"
            compression_settings = {
              content_types_to_compress = [
                "application/json",
                "text/css",
                "text/html"
              ]
              is_compression_enabled = true
            }
          }
          rule_sets = [
            {
              id = module.test.rule_set_ids["ruleset-01"]
            }
          ]
        }
      }
      tags = {
        EndpointType = "AFD"
      }
    }
  }
  # Custom Domains with different TLS configurations
  custom_domains = {
    "custom-domain-01" = {
      name      = "${module.naming.cdn_profile.name_unique}customdom1"
      host_name = "${module.naming.cdn_profile.name_unique}customdom1.azurewebsites.net"
      tls_settings = {
        certificate_type    = "ManagedCertificate"
        minimum_tls_version = "TLS12"
      }
    }
    "custom-domain-02" = {
      name      = "${module.naming.cdn_profile.name_unique}customdom2"
      host_name = "${module.naming.cdn_profile.name_unique}customdom2.azurewebsites.net"
      tls_settings = {
        certificate_type      = "ManagedCertificate"
        minimum_tls_version   = "TLS12"
        cipher_suite_set_type = "TLS12_2022"
      }
    }
    "custom-domain-03" = {
      name      = "${module.naming.cdn_profile.name_unique}customdom3"
      host_name = "${module.naming.cdn_profile.name_unique}customdom3.azurewebsites.net"
      tls_settings = {
        certificate_type      = "ManagedCertificate"
        minimum_tls_version   = "TLS13"
        cipher_suite_set_type = "Customized"
        customized_cipher_suite_set = {
          cipher_suite_set_for_tls13 = [
            "TLS_AES_128_GCM_SHA256",
            "TLS_AES_256_GCM_SHA384"
          ]
        }
      }
    }
  }
  enable_telemetry = var.enable_telemetry
  location         = "global"
  # Managed Identity - both system and user assigned
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }
  # Origin Groups with multiple origins and comprehensive settings
  origin_groups = {
    "origin-group-01" = {
      name = "${module.naming.cdn_profile.name_unique}origingrp1"
      load_balancing_settings = {
        additional_latency_in_milliseconds = 50
        sample_size                        = 4
        successful_samples_required        = 3
      }
      health_probe_settings = {
        probe_interval_in_seconds = 240
        probe_path                = "/"
        probe_protocol            = "Https"
        probe_request_type        = "HEAD"
      }
      session_affinity_state                                         = "Disabled"
      traffic_restoration_time_to_healed_or_new_endpoints_in_minutes = 10
      origins = {
        "origin-01" = {
          name                           = "${module.naming.cdn_profile.name_unique}origin1"
          host_name                      = "${azurerm_storage_account.this.name}.blob.core.windows.net"
          http_port                      = 80
          https_port                     = 443
          priority                       = 1
          weight                         = 1000
          enabled_state                  = "Enabled"
          enforce_certificate_name_check = true
        }
      }
    }
    "origin-group-02" = {
      name = "${module.naming.cdn_profile.name_unique}origingrp2"
      load_balancing_settings = {
        additional_latency_in_milliseconds = 100
        sample_size                        = 6
        successful_samples_required        = 4
      }
      session_affinity_state                                         = "Disabled"
      traffic_restoration_time_to_healed_or_new_endpoints_in_minutes = 10
      origins = {
        "origin-02" = {
          name                           = "${module.naming.cdn_profile.name_unique}origin2"
          host_name                      = "${azurerm_storage_account.this.name}.blob.core.windows.net"
          http_port                      = 80
          https_port                     = 443
          priority                       = 1
          weight                         = 1000
          enabled_state                  = "Enabled"
          enforce_certificate_name_check = true
        }
      }
    }
  }
  origin_response_timeout_seconds = 240
  # Rule Sets with comprehensive rules
  rule_sets = {
    "ruleset-01" = {
      name = "${replace(module.naming.cdn_profile.name_unique, "-", "")}ruleset1"
      rules = {
        "rule-01" = {
          name                      = "${replace(module.naming.cdn_profile.name_unique, "-", "")}rule1"
          order                     = 1
          match_processing_behavior = "Continue"
          actions = [
            {
              name = "UrlRedirect"
              parameters = {
                typeName            = "DeliveryRuleUrlRedirectActionParameters"
                redirectType        = "PermanentRedirect"
                destinationProtocol = "Https"
                customPath          = "/v2/api/"
                customHostname      = "api.example.com"
              }
            }
          ]
        }
      }
    }
  }
  # Tags
  tags = {
    Environment = "Test"
    Application = "CDN"
    CostCenter  = "12345"
    Owner       = "TestTeam"
  }

  depends_on = [
    azurerm_storage_account.this,
    azurerm_user_assigned_identity.this,
    azurerm_log_analytics_workspace.this,
    azurerm_eventhub.this
  ]
}
