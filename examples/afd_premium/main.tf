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

# Deploy WAF Policy as dependency
module "waf_policy" {
  source  = "Azure/avm-res-network-frontdoorwebapplicationfirewallpolicy/azurerm"
  version = "~> 0.1"

  mode                = "Prevention"
  name                = "${replace(module.naming.firewall_policy.name_unique, "-", "")}waf"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Premium_AzureFrontDoor"
  enable_telemetry    = var.enable_telemetry
}

# This is the module call - Azure Front Door Premium with full configuration
module "test" {
  source = "../../"

  name              = "${module.naming.cdn_profile.name_unique}afd"
  resource_group_id = azurerm_resource_group.this.id
  sku_name          = "Premium_AzureFrontDoor"
  # AFD Endpoints
  afd_endpoints = {
    "endpoint-01" = {
      name = "${module.naming.cdn_profile.name_unique}afdendpoint"
      routes = {
        "route-01" = {
          name            = "${module.naming.cdn_profile.name_unique}route"
          origin_group_id = module.test.origin_group_ids["origin-group-01"]
          custom_domains = [
            {
              id = module.test.custom_domain_ids["custom-domain-01"]
            }
          ]
          rule_sets = [
            {
              id = module.test.rule_set_ids["ruleset-01"]
            }
          ]
          patterns_to_match   = ["/*"]
          supported_protocols = ["Http", "Https"]
        }
      }
    }
  }
  # Custom Domains
  custom_domains = {
    "custom-domain-01" = {
      name      = "${module.naming.cdn_profile.name_unique}customdomain"
      host_name = "${module.naming.cdn_profile.name_unique}customdomain.azurewebsites.net"
      tls_settings = {
        certificate_type    = "ManagedCertificate"
        minimum_tls_version = "TLS12"
      }
    }
  }
  enable_telemetry = var.enable_telemetry
  location         = "global"
  # Origin Groups
  origin_groups = {
    "origin-group-01" = {
      name = "${module.naming.cdn_profile.name_unique}origingroup"
      load_balancing_settings = {
        additional_latency_in_milliseconds = 50
        sample_size                        = 4
        successful_samples_required        = 3
      }
      origins = {
        "origin-01" = {
          name      = "${module.naming.cdn_profile.name_unique}origin"
          host_name = "${module.naming.cdn_profile.name_unique}origin.azurewebsites.net"
        }
      }
    }
  }
  origin_response_timeout_seconds = 60
  # Rule Sets
  rule_sets = {
    "ruleset-01" = {
      name = "${replace(module.naming.cdn_profile.name_unique, "-", "")}ruleset"
      rules = {
        "rule-01" = {
          name  = "${replace(module.naming.cdn_profile.name_unique, "-", "")}rule"
          order = 1
          actions = [
            {
              name = "UrlRedirect"
              parameters = {
                typeName            = "DeliveryRuleUrlRedirectActionParameters"
                redirectType        = "PermanentRedirect"
                destinationProtocol = "Https"
                customPath          = "/test123"
                customHostname      = "dev-testfd.azure.test.org"
              }
            }
          ]
        }
      }
    }
  }
  # Security Policies
  security_policies = {
    "security-policy-01" = {
      name                   = "${replace(module.naming.cdn_profile.name_unique, "-", "")}secpol"
      waf_policy_resource_id = module.waf_policy.resource_id
      associations = [
        {
          domains = [
            {
              id = module.test.custom_domain_ids["custom-domain-01"]
            }
          ]
          patterns_to_match = ["/*"]
        }
      ]
    }
  }

  depends_on = [module.waf_policy]
}
