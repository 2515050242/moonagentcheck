///|
/// Named policy presets keep application adapters from scattering magic
/// retry and permission values through their integration code.
pub enum PolicyProfile {
  Permissive
  ReadOnly
  Ticketing
  DataPipeline
  Strict
} derive(Eq, Debug)

///|
/// A policy plus the configuration location that supplied it.
///
/// The source is deliberately supplied outside the observed event stream: a
/// trace must not be able to grant itself extra tools by claiming a policy.
pub struct PolicyContext {
  source : String
  policy : EvaluationPolicy
}

///|
/// Create an auditable policy context for an adapter, CI config, or test.
///
/// `source` must be non-empty when the context is evaluated. It is a human
/// readable identifier such as `ci/read-only-policy`, not a credential.
pub fn PolicyContext::new(
  source : String,
  policy : EvaluationPolicy,
) -> PolicyContext {
  { source, policy, }
}

///|
/// Build a named context from one of the built-in policy profiles.
pub fn PolicyContext::from_profile(
  source : String,
  profile : PolicyProfile,
) -> PolicyContext {
  PolicyContext::new(source, policy_for_profile(profile))
}

///|
/// Return whether both the policy and its audit source are usable.
pub fn PolicyContext::is_valid(context : PolicyContext) -> Bool {
  context.source != "" && policy_is_valid(context.policy)
}

///|
/// Apply a policy context while retaining evidence of which configuration
/// supplied the allowlist. Legacy evaluation entry points remain available for
/// callers that do not need policy provenance.
pub fn evaluate_with_context(
  events : Array[Event],
  context : PolicyContext,
) -> Array[Violation] {
  let violations : Array[Violation] = []
  if context.source == "" {
    violations.push({
      rule: "missing-policy-source",
      event_index: -1,
      message: "policy source is empty",
    })
  }
  for violation in evaluate_with_policy(events, context.policy) {
    violations.push(violation)
  }
  violations
}

///|
pub fn policy_profile_name(profile : PolicyProfile) -> String {
  match profile {
    Permissive => "permissive"
    ReadOnly => "read-only"
    Ticketing => "ticketing"
    DataPipeline => "data-pipeline"
    Strict => "strict"
  }
}

///|
pub fn policy_for_profile(profile : PolicyProfile) -> EvaluationPolicy {
  match profile {
    Permissive => EvaluationPolicy::new(3, None)
    ReadOnly =>
      EvaluationPolicy::new(1, Some(["read_file", "read_csv", "list_files"]))
    Ticketing =>
      EvaluationPolicy::new(
        2,
        Some(["get_ticket", "update_ticket", "comment_ticket"]),
      )
    DataPipeline =>
      EvaluationPolicy::new(
        2,
        Some(["read_csv", "transform_rows", "write_csv"]),
      )
    Strict => EvaluationPolicy::new(0, Some([]))
  }
}

///|
pub fn policy_profile_from_name(name : String) -> PolicyProfile? {
  match name {
    "permissive" => Some(Permissive)
    "read-only" => Some(ReadOnly)
    "ticketing" => Some(Ticketing)
    "data-pipeline" => Some(DataPipeline)
    "strict" => Some(Strict)
    _ => None
  }
}

///|
pub fn policy_allows_tool(policy : EvaluationPolicy, tool : String) -> Bool {
  match policy.tool_allowlist {
    None => true
    Some(allowlist) => allowlist.contains(tool)
  }
}

///|
pub fn policy_is_restricted(policy : EvaluationPolicy) -> Bool {
  policy.tool_allowlist is Some(_)
}

///|
pub fn policy_is_valid(policy : EvaluationPolicy) -> Bool {
  policy.max_retries >= 0
}

///|
pub fn policy_retry_allowed(policy : EvaluationPolicy, attempts : Int) -> Bool {
  policy_is_valid(policy) && attempts <= policy.max_retries
}

///|
pub fn policy_remaining_retries(
  policy : EvaluationPolicy,
  attempts : Int,
) -> Int {
  let remaining = policy.max_retries - attempts
  if remaining < 0 {
    0
  } else {
    remaining
  }
}

///|
pub fn unique_strings(values : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for value in values {
    if !result.contains(value) {
      result.push(value)
    }
  }
  result
}

///|
pub fn policy_tools(policy : EvaluationPolicy) -> Array[String] {
  match policy.tool_allowlist {
    None => []
    Some(allowlist) => unique_strings(allowlist)
  }
}

///|
pub fn policy_with_max_retries(
  policy : EvaluationPolicy,
  max_retries : Int,
) -> EvaluationPolicy {
  EvaluationPolicy::new(max_retries, policy.tool_allowlist)
}

///|
pub fn policy_with_tools(
  policy : EvaluationPolicy,
  tools : Array[String],
) -> EvaluationPolicy {
  EvaluationPolicy::new(policy.max_retries, Some(unique_strings(tools)))
}

///|
pub fn policy_unrestricted(policy : EvaluationPolicy) -> EvaluationPolicy {
  EvaluationPolicy::new(policy.max_retries, None)
}

///|
pub fn policy_with_tool(
  policy : EvaluationPolicy,
  tool : String,
) -> EvaluationPolicy {
  let tools = policy_tools(policy)
  if !tools.contains(tool) {
    tools.push(tool)
  }
  policy_with_tools(policy, tools)
}

///|
pub fn policy_without_tool(
  policy : EvaluationPolicy,
  tool : String,
) -> EvaluationPolicy {
  policy_with_tools(policy, policy_tools(policy).filter(value => value != tool))
}

///|
pub fn allowlist_union(
  left : Array[String],
  right : Array[String],
) -> Array[String] {
  let result = unique_strings(left)
  for tool in right {
    if !result.contains(tool) {
      result.push(tool)
    }
  }
  result
}

///|
pub fn allowlist_intersection(
  left : Array[String],
  right : Array[String],
) -> Array[String] {
  unique_strings(left.filter(tool => right.contains(tool)))
}

///|
pub fn allowlist_difference(
  left : Array[String],
  right : Array[String],
) -> Array[String] {
  unique_strings(left.filter(tool => !right.contains(tool)))
}

///|
pub struct PolicyDecision {
  allowed : Bool
  reason : String
  tool : String
  operation_id : String?
  attempt : Int
  remaining_retries : Int
}

///|
pub fn PolicyDecision::is_allowed(decision : PolicyDecision) -> Bool {
  decision.allowed
}

///|
pub fn PolicyDecision::render(decision : PolicyDecision) -> String {
  let operation = match decision.operation_id {
    Some(value) => value
    None => "-"
  }
  decision.tool +
  " operation=" +
  operation +
  " attempt=" +
  decision.attempt.to_string() +
  " allowed=" +
  decision.allowed.to_string() +
  " reason=" +
  decision.reason
}

///|
pub fn decide_tool(
  policy : EvaluationPolicy,
  tool : String,
  operation_id : String?,
  attempt : Int,
) -> PolicyDecision {
  if !policy_is_valid(policy) {
    {
      allowed: false,
      reason: "invalid-policy",
      tool,
      operation_id,
      attempt,
      remaining_retries: 0,
    }
  } else if !policy_allows_tool(policy, tool) {
    {
      allowed: false,
      reason: "tool-not-allowed",
      tool,
      operation_id,
      attempt,
      remaining_retries: policy_remaining_retries(policy, attempt),
    }
  } else if !policy_retry_allowed(policy, attempt) {
    {
      allowed: false,
      reason: "retry-limit",
      tool,
      operation_id,
      attempt,
      remaining_retries: 0,
    }
  } else {
    {
      allowed: true,
      reason: "allowed",
      tool,
      operation_id,
      attempt,
      remaining_retries: policy_remaining_retries(policy, attempt),
    }
  }
}

///|
pub fn decide_event(
  policy : EvaluationPolicy,
  event : Event,
  attempts : Int,
) -> PolicyDecision {
  decide_tool(policy, event.tool, event.operation_id, attempts)
}

///|
pub fn policy_decisions(
  events : Array[Event],
  policy : EvaluationPolicy,
) -> Array[PolicyDecision] {
  let decisions : Array[PolicyDecision] = []
  let attempts : Map[String, Int] = Map([])
  for event in events {
    if event.kind == "call" {
      let attempt = match event.operation_id {
        Some(operation) => {
          let next = match attempts.get(operation) {
            Some(value) => value + 1
            None => 1
          }
          attempts[operation] = next
          next
        }
        None => 1
      }
      decisions.push(decide_event(policy, event, attempt))
    }
  }
  decisions
}

///|
pub fn allowed_decisions(
  decisions : Array[PolicyDecision],
) -> Array[PolicyDecision] {
  decisions.filter(decision => decision.allowed)
}

///|
pub fn denied_decisions(
  decisions : Array[PolicyDecision],
) -> Array[PolicyDecision] {
  decisions.filter(decision => !decision.allowed)
}

///|
pub struct PolicyAudit {
  total_calls : Int
  allowed_calls : Int
  denied_calls : Int
  invalid_calls : Int
  retry_denials : Int
  tool_denials : Int
}

///|
pub fn audit_policy(
  events : Array[Event],
  policy : EvaluationPolicy,
) -> PolicyAudit {
  let decisions = policy_decisions(events, policy)
  let mut retry_denials = 0
  let mut tool_denials = 0
  let mut invalid_calls = 0
  for decision in decisions {
    if decision.reason == "retry-limit" {
      retry_denials = retry_denials + 1
    } else if decision.reason == "tool-not-allowed" {
      tool_denials = tool_denials + 1
    } else if decision.reason == "invalid-policy" {
      invalid_calls = invalid_calls + 1
    }
  }
  {
    total_calls: decisions.length(),
    allowed_calls: allowed_decisions(decisions).length(),
    denied_calls: denied_decisions(decisions).length(),
    invalid_calls,
    retry_denials,
    tool_denials,
  }
}

///|
pub struct PolicyComparison {
  same_retry_limit : Bool
  same_restriction : Bool
  added_tools : Array[String]
  removed_tools : Array[String]
}

///|
pub fn compare_policies(
  left : EvaluationPolicy,
  right : EvaluationPolicy,
) -> PolicyComparison {
  let left_tools = policy_tools(left)
  let right_tools = policy_tools(right)
  {
    same_retry_limit: left.max_retries == right.max_retries,
    same_restriction: left_is_same_restriction(left, right),
    added_tools: allowlist_difference(right_tools, left_tools),
    removed_tools: allowlist_difference(left_tools, right_tools),
  }
}

///|
fn left_is_same_restriction(
  left : EvaluationPolicy,
  right : EvaluationPolicy,
) -> Bool {
  match (left.tool_allowlist, right.tool_allowlist) {
    (None, None) => true
    (Some(left_tools), Some(right_tools)) =>
      allowlist_difference(left_tools, right_tools).length() == 0 &&
      allowlist_difference(right_tools, left_tools).length() == 0
    _ => false
  }
}

///|
pub fn policy_is_stricter(
  left : EvaluationPolicy,
  right : EvaluationPolicy,
) -> Bool {
  let comparison = compare_policies(left, right)
  left.max_retries <= right.max_retries &&
  left.tool_allowlist is Some(_) &&
  (right.tool_allowlist is None || comparison.removed_tools.length() > 0)
}

///|
pub fn policy_json(policy : EvaluationPolicy) -> String {
  let tools = match policy.tool_allowlist {
    None => Json::null()
    Some(values) => Json::array(unique_strings(values).map(tool => Json(tool)))
  }
  Json::object({
    "max_retries": Json(policy.max_retries),
    "tool_allowlist": tools,
    "restricted": Json(policy_is_restricted(policy)),
    "valid": Json(policy_is_valid(policy)),
  }).stringify()
}

///|
pub fn policy_profile_json(profile : PolicyProfile) -> String {
  let policy = policy_for_profile(profile)
  let tools = match policy.tool_allowlist {
    None => Json::null()
    Some(values) => Json::array(unique_strings(values).map(tool => Json(tool)))
  }
  Json::object({
    "profile": Json(policy_profile_name(profile)),
    "max_retries": Json(policy.max_retries),
    "tool_allowlist": tools,
    "restricted": Json(policy_is_restricted(policy)),
  }).stringify()
}

///|
pub fn policies_for_profiles(
  profiles : Array[PolicyProfile],
) -> Array[EvaluationPolicy] {
  profiles.map(profile => policy_for_profile(profile))
}
