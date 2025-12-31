variable "name" {
  type        = string
  description = <<NAME
The name of the rule set resource.

Constraints:
- Must be between 1 and 260 characters
- Must start with a letter
- Can only contain alphanumeric characters

Example Input:

```hcl
name = "SecurityRules"
```
NAME

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,259}$", var.name))
    error_message = "The name must be between 1 and 260 characters, start with a letter, and contain only alphanumeric characters."
  }
}

variable "profile_id" {
  type        = string
  description = <<PROFILE_ID
The full Azure Resource ID of the CDN profile where this rule set will be created.

This should be in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}`

Example Input:

```hcl
profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile"
```
PROFILE_ID
}

variable "rules" {
  type = map(object({
    name  = string
    order = number
    actions = optional(list(object({
      name = string
      parameters = optional(object({
        # CacheExpiration action parameters
        cacheBehavior = optional(string)
        cacheDuration = optional(string)
        cacheType     = optional(string)
        # CacheKeyQueryString action parameters
        queryParameters     = optional(string)
        queryStringBehavior = optional(string)
        # Header action parameters
        headerAction = optional(string)
        headerName   = optional(string)
        value        = optional(string)
        # OriginGroupOverride action parameters
        originGroup = optional(object({
          id = optional(string)
        }))
        # RouteConfigurationOverride action parameters
        cacheConfiguration  = optional(any)
        originGroupOverride = optional(any)
        # UrlRedirect action parameters
        customFragment      = optional(string)
        customHostname      = optional(string)
        customPath          = optional(string)
        customQueryString   = optional(string)
        destinationProtocol = optional(string)
        redirectType        = optional(string)
        # UrlRewrite action parameters
        destination           = optional(string)
        preserveUnmatchedPath = optional(bool)
        sourcePattern         = optional(string)
        # UrlSigning action parameters
        algorithm = optional(string)
        parameterNameOverride = optional(list(object({
          paramIndicator = optional(string)
          paramName      = optional(string)
        })))
        # Common parameter
        typeName = optional(string)
      }))
    })), [])
    conditions = optional(list(object({
      name = string
      parameters = optional(object({
        # Match condition parameters (common to most conditions)
        matchValues     = optional(list(string))
        negateCondition = optional(bool)
        operator        = optional(string)
        selector        = optional(string)
        transforms      = optional(list(string))
        # Common parameter
        typeName = optional(string)
      }))
    })), [])
    match_processing_behavior = optional(string, "Continue")
  }))
  default     = {}
  description = <<RULES
A map of routing rules to include in this rule set. Rules modify request/response behavior based on conditions.

- `<map key>` - Use a custom map key to define each rule configuration
  - `name`  = (Required) The name of the rule. Must start with a letter and contain only alphanumeric characters.
  - `order` = (Required) The execution order of the rule. Lower values execute first. Range: 0-1000.
  - `actions` = (Optional) List of actions to perform when conditions match
    - `name` = (Required) The action type (e.g., `CacheExpiration`, `UrlRedirect`, `ModifyRequestHeader`)
    - `parameters` = (Optional) Action-specific parameters (varies by action type)
  - `conditions` = (Optional) List of conditions that must be met for actions to execute
    - `name` = (Required) The condition type (e.g., `RequestUri`, `QueryString`, `RequestHeader`)
    - `parameters` = (Optional) Condition-specific parameters
      - `matchValues` = (Optional) Values to match against
      - `operator` = (Optional) Comparison operator (e.g., `Equal`, `Contains`, `BeginsWith`)
      - `negateCondition` = (Optional) Whether to negate the condition result
  - `match_processing_behavior` = (Optional) Whether to continue or stop processing after this rule. Possible values are `Continue` or `Stop`. Defaults to `Continue`.

Example Input:

```hcl
rules = {
  "redirect-http" = {
    name  = "RedirectToHttps"
    order = 1
    conditions = [{
      name = "RequestScheme"
      parameters = {
        operator    = "Equal"
        matchValues = ["HTTP"]
      }
    }]
    actions = [{
      name = "UrlRedirect"
      parameters = {
        redirectType        = "Moved"
        destinationProtocol = "Https"
      }
    }]
    match_processing_behavior = "Stop"
  }
}
```
RULES

  validation {
    condition     = alltrue([for k, r in var.rules : r.order >= 0])
    error_message = "Rule order must be a non-negative integer."
  }
  validation {
    condition     = alltrue([for k, r in var.rules : can(regex("^[a-zA-Z][a-zA-Z0-9]{0,259}$", r.name))])
    error_message = "Rule names must be between 1 and 260 characters, start with a letter, and contain only alphanumeric characters."
  }
  validation {
    condition = alltrue([
      for k, r in var.rules :
      r.match_processing_behavior == null || contains(["Continue", "Stop"], r.match_processing_behavior)
    ])
    error_message = "match_processing_behavior must be either 'Continue' or 'Stop'."
  }
}
