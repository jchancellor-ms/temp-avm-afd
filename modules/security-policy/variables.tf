variable "associations" {
  type = list(object({
    domains = list(object({
      id = string
    }))
    patterns_to_match = list(string)
  }))
  description = <<ASSOCIATIONS
List of associations that define which domains and URL patterns this security policy protects.

Each association binds the WAF policy to specific custom domains or AFD endpoints and defines which URL patterns should be protected.

- `domains` = (Required) List of domain resource IDs to protect
  - `id` = (Required) The full Azure Resource ID of the custom domain or AFD endpoint
- `patterns_to_match` = (Required) List of URL path patterns to protect (e.g., `["/api/*", "/*"]`)

Example Input:

```hcl
associations = [
  {
    domains = [
      {
        id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/customDomains/www-example-com"
      }
    ]
    patterns_to_match = ["/api/*", "/admin/*"]
  }
]
```
ASSOCIATIONS

  validation {
    condition     = length(var.associations) > 0
    error_message = "At least one association must be specified."
  }
}

variable "name" {
  type        = string
  description = <<NAME
The name of the security policy resource.

Constraints:
- Must be between 1 and 260 characters
- Can only contain alphanumeric characters and hyphens

Example Input:

```hcl
name = "production-waf-policy"
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
The full Azure Resource ID of the CDN profile where this security policy will be created.

This should be in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}`

Example Input:

```hcl
profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile"
```
PROFILE_ID
}

variable "embedded_waf_policy" {
  type = object({
    etag = optional(string)
    sku = optional(object({
      name = string
    }))
    properties = optional(object({
      custom_rules = optional(object({
        rules = optional(list(object({
          name                           = optional(string)
          priority                       = number
          rule_type                      = string
          action                         = string
          enabled_state                  = optional(string, "Enabled")
          rate_limit_duration_in_minutes = optional(number)
          rate_limit_threshold           = optional(number)
          match_conditions = list(object({
            match_variable   = string
            operator         = string
            match_value      = list(string)
            selector         = optional(string)
            negate_condition = optional(bool, false)
            transforms       = optional(list(string), [])
          }))
          group_by = optional(list(object({
            variable_name = string
          })), [])
        })))
      }))
      managed_rules = optional(object({
        managed_rule_sets = optional(list(object({
          rule_set_type    = string
          rule_set_version = string
          rule_set_action  = optional(string)
          exclusions = optional(list(object({
            match_variable          = string
            selector                = string
            selector_match_operator = string
          })), [])
          rule_group_overrides = optional(list(object({
            rule_group_name = string
            exclusions = optional(list(object({
              match_variable          = string
              selector                = string
              selector_match_operator = string
            })), [])
            rules = optional(list(object({
              rule_id       = string
              enabled_state = optional(string)
              action        = optional(string)
              exclusions = optional(list(object({
                match_variable          = string
                selector                = string
                selector_match_operator = string
              })), [])
            })), [])
          })), [])
        })))
      }))
      policy_settings = optional(object({
        enabled_state                              = optional(string, "Enabled")
        mode                                       = optional(string, "Prevention")
        request_body_check                         = optional(string)
        custom_block_response_status_code          = optional(number)
        custom_block_response_body                 = optional(string)
        redirect_url                               = optional(string)
        captcha_expiration_in_minutes              = optional(number)
        javascript_challenge_expiration_in_minutes = optional(number)
        log_scrubbing = optional(object({
          state = optional(string, "Enabled")
          scrubbing_rules = optional(list(object({
            match_variable          = string
            selector_match_operator = string
            selector                = optional(string)
            state                   = optional(string, "Enabled")
          })), [])
        }))
      }))
    }))
  })
  default     = null
  description = <<EMBEDDED_WAF_POLICY
Embedded Web Application Firewall policy configuration for inline WAF policy definition.

Required when `type` is `WebApplicationFirewallEmbedded`. Mutually exclusive with `waf_policy_resource_id`.

This allows you to define the complete WAF policy inline rather than referencing an external policy resource. The embedded policy supports custom rules, managed rule sets, and policy settings.

- `etag` = (Optional) The entity tag for concurrency control
- `sku` = (Optional) The SKU configuration
  - `name` = (Required) The SKU name (e.g., `Premium_AzureFrontDoor`, `Standard_AzureFrontDoor`)
- `properties` = (Optional) The WAF policy properties
  - `custom_rules` = (Optional) Custom security rules
    - `rules` = (Optional) List of custom rule definitions
      - `name` = (Optional) Rule name
      - `priority` = (Required) Rule priority (1-1000, lower executes first)
      - `rule_type` = (Required) Rule type (`MatchRule` or `RateLimitRule`)
      - `action` = (Required) Action to take (`Allow`, `Block`, `Log`, `Redirect`)
      - `enabled_state` = (Optional) Whether rule is enabled (`Enabled` or `Disabled`)
      - `rate_limit_duration_in_minutes` = (Optional) Rate limit window (for RateLimitRule)
      - `rate_limit_threshold` = (Optional) Rate limit threshold (for RateLimitRule)
      - `match_conditions` = (Required) List of conditions to match
        - `match_variable` = (Required) Variable to inspect (e.g., `RemoteAddr`, `RequestUri`, `QueryString`)
        - `operator` = (Required) Comparison operator (e.g., `IPMatch`, `Contains`, `Equal`)
        - `match_value` = (Required) Values to match against
        - `selector` = (Optional) Specific field to inspect (e.g., header name)
        - `negate_condition` = (Optional) Negate the condition result
        - `transforms` = (Optional) Transforms to apply before matching (e.g., `Lowercase`, `UrlDecode`)
      - `group_by` = (Optional) Variables to group by for rate limiting
        - `variable_name` = (Required) Variable name to group by
  - `managed_rules` = (Optional) Managed rule set configuration
    - `managed_rule_sets` = (Optional) List of managed rule sets to enable
      - `rule_set_type` = (Required) Rule set type (e.g., `Microsoft_DefaultRuleSet`, `Microsoft_BotManagerRuleSet`)
      - `rule_set_version` = (Required) Rule set version (e.g., `2.0`, `1.0`)
      - `rule_set_action` = (Optional) Default action for the rule set
      - `exclusions` = (Optional) Global exclusions for the rule set
      - `rule_group_overrides` = (Optional) Override configurations for specific rule groups
        - `rule_group_name` = (Required) Name of the rule group to override
        - `exclusions` = (Optional) Exclusions for this rule group
        - `rules` = (Optional) Individual rule overrides
          - `rule_id` = (Required) The rule ID to override
          - `enabled_state` = (Optional) Override enabled state
          - `action` = (Optional) Override action
          - `exclusions` = (Optional) Exclusions for this specific rule
  - `policy_settings` = (Optional) General policy settings
    - `enabled_state` = (Optional) Whether policy is enabled (`Enabled` or `Disabled`)
    - `mode` = (Optional) Policy mode (`Detection` or `Prevention`)
    - `request_body_check` = (Optional) Whether to inspect request bodies
    - `custom_block_response_status_code` = (Optional) HTTP status code for blocked requests
    - `custom_block_response_body` = (Optional) Custom response body for blocked requests
    - `redirect_url` = (Optional) URL to redirect blocked requests
    - `captcha_expiration_in_minutes` = (Optional) CAPTCHA challenge expiration
    - `javascript_challenge_expiration_in_minutes` = (Optional) JavaScript challenge expiration
    - `log_scrubbing` = (Optional) Configuration for scrubbing sensitive data from logs
      - `state` = (Optional) Whether log scrubbing is enabled
      - `scrubbing_rules` = (Optional) List of scrubbing rules
        - `match_variable` = (Required) Variable to scrub (e.g., `RequestHeader`, `QueryString`)
        - `selector_match_operator` = (Required) How to match selector (`Equals`, `EqualsAny`)
        - `selector` = (Optional) Specific field to scrub
        - `state` = (Optional) Whether this rule is enabled

Example Input:

```hcl
embedded_waf_policy = {
  sku = {
    name = "Premium_AzureFrontDoor"
  }
  properties = {
    policy_settings = {
      enabled_state = "Enabled"
      mode          = "Prevention"
    }
    managed_rules = {
      managed_rule_sets = [{
        rule_set_type    = "Microsoft_DefaultRuleSet"
        rule_set_version = "2.0"
      }]
    }
    custom_rules = {
      rules = [{
        name      = "BlockMaliciousIPs"
        priority  = 100
        rule_type = "MatchRule"
        action    = "Block"
        match_conditions = [{
          match_variable = "RemoteAddr"
          operator       = "IPMatch"
          match_value    = ["192.0.2.0/24"]
        }]
      }]
    }
  }
}
```
EMBEDDED_WAF_POLICY
}

variable "type" {
  type        = string
  default     = "WebApplicationFirewall"
  description = <<TYPE
The type of security policy to create.

Possible values:
- `WebApplicationFirewall` - Reference an existing WAF policy via `waf_policy_resource_id` (default)
- `WebApplicationFirewallEmbedded` - Use an embedded WAF policy configuration via `embedded_waf_policy`

Example Input:

```hcl
type = "WebApplicationFirewall"
```
TYPE

  validation {
    condition     = contains(["WebApplicationFirewall", "WebApplicationFirewallEmbedded"], var.type)
    error_message = "The type must be either 'WebApplicationFirewall' or 'WebApplicationFirewallEmbedded'."
  }
}

variable "waf_policy_resource_id" {
  type        = string
  default     = null
  description = <<WAF_POLICY_RESOURCE_ID
The full Azure Resource ID of an existing Azure Front Door WAF policy.

Required when `type` is `WebApplicationFirewall`. Mutually exclusive with `embedded_waf_policy`.

This allows you to reference a separately managed WAF policy resource that can be shared across multiple security policies.

Example Input:

```hcl
waf_policy_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/frontDoorWebApplicationFirewallPolicies/my-waf-policy"
```
WAF_POLICY_RESOURCE_ID
}
