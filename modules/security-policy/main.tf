locals {
  # Build associations with proper property names
  associations = [
    for assoc in var.associations : {
      domains         = assoc.domains
      patternsToMatch = assoc.patterns_to_match
    }
  ]
  parameters = var.type == "WebApplicationFirewall" ? local.parameters_waf : local.parameters_embedded
  parameters_embedded = var.type == "WebApplicationFirewallEmbedded" && var.embedded_waf_policy != null ? {
    type         = var.type
    associations = local.associations
    wafPolicy = merge(
      var.embedded_waf_policy.etag != null ? { etag = var.embedded_waf_policy.etag } : {},
      var.embedded_waf_policy.sku != null ? { sku = var.embedded_waf_policy.sku } : {},
      var.embedded_waf_policy.properties != null ? {
        properties = merge(
          var.embedded_waf_policy.properties.custom_rules != null ? {
            customRules = {
              rules = [
                for rule in var.embedded_waf_policy.properties.custom_rules.rules : merge(
                  { priority = rule.priority },
                  { ruleType = rule.rule_type },
                  { action = rule.action },
                  rule.name != null ? { name = rule.name } : {},
                  rule.enabled_state != null ? { enabledState = rule.enabled_state } : {},
                  rule.rate_limit_duration_in_minutes != null ? { rateLimitDurationInMinutes = rule.rate_limit_duration_in_minutes } : {},
                  rule.rate_limit_threshold != null ? { rateLimitThreshold = rule.rate_limit_threshold } : {},
                  {
                    matchConditions = [
                      for cond in rule.match_conditions : merge(
                        { matchVariable = cond.match_variable },
                        { operator = cond.operator },
                        { matchValue = cond.match_value },
                        cond.selector != null ? { selector = cond.selector } : {},
                        cond.negate_condition != null ? { negateCondition = cond.negate_condition } : {},
                        length(cond.transforms) > 0 ? { transforms = cond.transforms } : {}
                      )
                    ]
                  },
                  length(rule.group_by) > 0 ? {
                    groupBy = [
                      for gb in rule.group_by : {
                        variableName = gb.variable_name
                      }
                    ]
                  } : {}
                )
              ]
            }
          } : {},
          var.embedded_waf_policy.properties.managed_rules != null ? {
            managedRules = {
              managedRuleSets = [
                for rs in var.embedded_waf_policy.properties.managed_rules.managed_rule_sets : merge(
                  { ruleSetType = rs.rule_set_type },
                  { ruleSetVersion = rs.rule_set_version },
                  rs.rule_set_action != null ? { ruleSetAction = rs.rule_set_action } : {},
                  length(rs.exclusions) > 0 ? {
                    exclusions = [
                      for ex in rs.exclusions : {
                        matchVariable         = ex.match_variable
                        selector              = ex.selector
                        selectorMatchOperator = ex.selector_match_operator
                      }
                    ]
                  } : {},
                  length(rs.rule_group_overrides) > 0 ? {
                    ruleGroupOverrides = [
                      for rgo in rs.rule_group_overrides : merge(
                        { ruleGroupName = rgo.rule_group_name },
                        length(rgo.exclusions) > 0 ? {
                          exclusions = [
                            for ex in rgo.exclusions : {
                              matchVariable         = ex.match_variable
                              selector              = ex.selector
                              selectorMatchOperator = ex.selector_match_operator
                            }
                          ]
                        } : {},
                        length(rgo.rules) > 0 ? {
                          rules = [
                            for r in rgo.rules : merge(
                              { ruleId = r.rule_id },
                              r.enabled_state != null ? { enabledState = r.enabled_state } : {},
                              r.action != null ? { action = r.action } : {},
                              length(r.exclusions) > 0 ? {
                                exclusions = [
                                  for ex in r.exclusions : {
                                    matchVariable         = ex.match_variable
                                    selector              = ex.selector
                                    selectorMatchOperator = ex.selector_match_operator
                                  }
                                ]
                              } : {}
                            )
                          ]
                        } : {}
                      )
                    ]
                  } : {}
                )
              ]
            }
          } : {},
          var.embedded_waf_policy.properties.policy_settings != null ? {
            policySettings = merge(
              var.embedded_waf_policy.properties.policy_settings.enabled_state != null ? { enabledState = var.embedded_waf_policy.properties.policy_settings.enabled_state } : {},
              var.embedded_waf_policy.properties.policy_settings.mode != null ? { mode = var.embedded_waf_policy.properties.policy_settings.mode } : {},
              var.embedded_waf_policy.properties.policy_settings.request_body_check != null ? { requestBodyCheck = var.embedded_waf_policy.properties.policy_settings.request_body_check } : {},
              var.embedded_waf_policy.properties.policy_settings.custom_block_response_status_code != null ? { customBlockResponseStatusCode = var.embedded_waf_policy.properties.policy_settings.custom_block_response_status_code } : {},
              var.embedded_waf_policy.properties.policy_settings.custom_block_response_body != null ? { customBlockResponseBody = var.embedded_waf_policy.properties.policy_settings.custom_block_response_body } : {},
              var.embedded_waf_policy.properties.policy_settings.redirect_url != null ? { redirectUrl = var.embedded_waf_policy.properties.policy_settings.redirect_url } : {},
              var.embedded_waf_policy.properties.policy_settings.captcha_expiration_in_minutes != null ? { captchaExpirationInMinutes = var.embedded_waf_policy.properties.policy_settings.captcha_expiration_in_minutes } : {},
              var.embedded_waf_policy.properties.policy_settings.javascript_challenge_expiration_in_minutes != null ? { javascriptChallengeExpirationInMinutes = var.embedded_waf_policy.properties.policy_settings.javascript_challenge_expiration_in_minutes } : {},
              var.embedded_waf_policy.properties.policy_settings.log_scrubbing != null ? {
                logScrubbing = merge(
                  var.embedded_waf_policy.properties.policy_settings.log_scrubbing.state != null ? { state = var.embedded_waf_policy.properties.policy_settings.log_scrubbing.state } : {},
                  length(var.embedded_waf_policy.properties.policy_settings.log_scrubbing.scrubbing_rules) > 0 ? {
                    scrubbingRules = [
                      for sr in var.embedded_waf_policy.properties.policy_settings.log_scrubbing.scrubbing_rules : merge(
                        { matchVariable = sr.match_variable },
                        { selectorMatchOperator = sr.selector_match_operator },
                        sr.selector != null ? { selector = sr.selector } : {},
                        sr.state != null ? { state = sr.state } : {}
                      )
                    ]
                  } : {}
                )
              } : {}
            )
          } : {}
        )
      } : {}
    )
  } : null
  # Build parameters based on type
  parameters_waf = var.type == "WebApplicationFirewall" ? {
    type = var.type
    wafPolicy = {
      id = var.waf_policy_resource_id
    }
    associations = local.associations
  } : null
}

resource "azapi_resource" "security_policy" {
  name      = var.name
  parent_id = var.profile_id
  type      = "Microsoft.Cdn/profiles/securityPolicies@2025-06-01"
  body = {
    properties = {
      parameters = local.parameters
    }
  }
}
