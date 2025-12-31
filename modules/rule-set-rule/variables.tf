variable "name" {
  type        = string
  description = <<NAME
The name of the routing rule.

Constraints:
- Must be between 1 and 260 characters
- Must start with a letter
- Can only contain alphanumeric characters

Example Input:

```hcl
name = "RedirectToHttps"
```
NAME

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,259}$", var.name))
    error_message = "The name must be between 1 and 260 characters, start with a letter, and contain only alphanumeric characters."
  }
}

variable "order" {
  type        = number
  description = <<ORDER
The execution order of this rule within the rule set.

Rules with lower order values are evaluated first. Order 0 is special - it always executes without requiring conditions.

Constraints:
- Must be non-negative (0 or greater)
- Lower values execute first
- Order 0 rules always execute (conditions are ignored)

Example Input:

```hcl
order = 1
```
ORDER

  validation {
    condition     = var.order >= 0
    error_message = "The order must be a non-negative integer."
  }
}

variable "rule_set_id" {
  type        = string
  description = <<RULE_SET_ID
The full Azure Resource ID of the rule set that will contain this rule.

This should be in the format:
`/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Cdn/profiles/{profileName}/ruleSets/{ruleSetName}`

Example Input:

```hcl
rule_set_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Cdn/profiles/my-profile/ruleSets/SecurityRules"
```
RULE_SET_ID
}

variable "actions" {
  type = list(object({
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
  }))
  default     = []
  description = <<ACTIONS
List of actions to execute when all rule conditions are satisfied.

Actions modify requests or responses, such as redirecting URLs, modifying headers, adjusting cache behavior, or rewriting URLs.

- `name` = (Required) The action type. Possible values:
  - `CacheExpiration` - Modify cache TTL
  - `CacheKeyQueryString` - Control query string caching
  - `ModifyRequestHeader` - Add/modify/delete request headers
  - `ModifyResponseHeader` - Add/modify/delete response headers
  - `OriginGroupOverride` - Route to a different origin group
  - `RouteConfigurationOverride` - Override route configuration
  - `UrlRedirect` - Redirect to a different URL
  - `UrlRewrite` - Rewrite request URL
  - `UrlSigning` - Configure URL signing
- `parameters` = (Optional) Action-specific parameters (structure varies by action type)

Example Input:

```hcl
actions = [
  {
    name = "UrlRedirect"
    parameters = {
      redirectType        = "Moved"
      destinationProtocol = "Https"
    }
  }
]
```
ACTIONS
}

variable "conditions" {
  type = list(object({
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
  }))
  default     = []
  description = <<CONDITIONS
List of conditions that must all be satisfied for the actions to execute.

Conditions evaluate request properties to determine if the rule should apply.

- `name` = (Required) The condition type. Possible values:
  - `RemoteAddress` - Client IP address
  - `RequestMethod` - HTTP method (GET, POST, etc.)
  - `RequestUri` - Full request URI
  - `QueryString` - Query string parameters
  - `RequestHeader` - Request header values
  - `RequestBody` - Request body content
  - `RequestScheme` - HTTP or HTTPS
  - `UrlPath` - URL path
  - `UrlFileExtension` - File extension
  - `UrlFileName` - File name
  - `HttpVersion` - HTTP protocol version
  - `Cookies` - Cookie values
  - `IsDevice` - Device type detection
  - `SocketAddress` - Socket address
  - `ClientPort` - Client port number
  - `ServerPort` - Server port number
  - `HostName` - Host header value
  - `SslProtocol` - TLS/SSL protocol version
- `parameters` = (Optional) Condition-specific parameters
  - `matchValues` = (Optional) Values to match against
  - `operator` = (Optional) Comparison operator (e.g., `Equal`, `Contains`, `IPMatch`)
  - `negateCondition` = (Optional) Negate the condition result
  - `selector` = (Optional) Specific field to inspect (e.g., header name)
  - `transforms` = (Optional) Transforms to apply before matching

Example Input:

```hcl
conditions = [
  {
    name = "RequestScheme"
    parameters = {
      operator    = "Equal"
      matchValues = ["HTTP"]
    }
  }
]
```
CONDITIONS
}

variable "match_processing_behavior" {
  type        = string
  default     = "Continue"
  description = <<MATCH_PROCESSING_BEHAVIOR
Determines whether the rules engine should continue processing remaining rules after this rule matches.

Possible values:
- `Continue` - Process remaining rules after this rule (default)
- `Stop` - Stop processing rules after this rule matches

Example Input:

```hcl
match_processing_behavior = "Stop"
```
MATCH_PROCESSING_BEHAVIOR

  validation {
    condition     = contains(["Continue", "Stop"], var.match_processing_behavior)
    error_message = "match_processing_behavior must be either 'Continue' or 'Stop'."
  }
}
