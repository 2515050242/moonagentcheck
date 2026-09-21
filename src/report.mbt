///|
/// Return the stable machine-readable code for a contract violation.
///
/// The code is safe for filtering and aggregation. Unknown rules deliberately
/// fall back to `unknown` so adapters can handle newer library versions.
pub fn violation_code(violation : Violation) -> String {
  rule_code(violation.rule)
}

///|
/// Return the stable machine-readable code for a violation rule.
pub fn rule_code(rule : String) -> String {
  match rule {
    "orphan-result" => "AGC001"
    "missing-result" => "AGC002"
    "retry-limit" => "AGC003"
    "duplicate-side-effect" => "AGC004"
    "write-without-call" => "AGC005"
    "duplicate-call-id" => "AGC006"
    "duplicate-result" => "AGC007"
    "missing-operation-id" => "AGC008"
    "failed-result" => "AGC009"
    "write-without-successful-result" => "AGC010"
    "result-call-mismatch" => "AGC011"
    "tool-not-allowed" => "AGC012"
    "invalid-event" => "AGC013"
    "unknown-event-kind" => "AGC014"
    "invalid-policy" => "AGC015"
    "write-call-mismatch" => "AGC016"
    "missing-policy-source" => "AGC017"
    _ => "unknown"
  }
}

///|
/// Serialize one policy-context evaluation for CI artifacts or offline review.
///
/// The report identifies the configuration source separately from observed
/// events, includes the actual policy values, and preserves violation order.
/// A blank source is reported as `AGC017` instead of silently losing the
/// provenance needed to interpret an allowlist decision.
pub fn evaluation_report_json(
  events : Array[Event],
  context : PolicyContext,
) -> String {
  let policy = context.policy
  let tools = match policy.tool_allowlist {
    None => Json::null()
    Some(values) => Json::array(unique_strings(values).map(tool => Json(tool)))
  }
  let violations = evaluate_with_context(events, context)
  Json::object({
    "policy_source": Json(context.source),
    "policy": Json::object({
      "max_retries": Json(policy.max_retries),
      "tool_allowlist": tools,
      "restricted": Json(policy_is_restricted(policy)),
      "valid": Json(policy_is_valid(policy)),
    }),
    "passed": Json(violations.length() == 0),
    "violations": Json::array(
      violations.map(violation => {
        Json::object({
          "code": Json(violation_code(violation)),
          "rule": Json(violation.rule),
          "event_index": Json(violation.event_index),
          "message": Json(violation.message),
        })
      }),
    ),
  }).stringify()
}

///|
/// Serialize evaluated scenarios as a compact, deterministic JSON report.
///
/// The report preserves the scenario and violation order supplied by
/// `evaluate_scenarios`. Each violation contains its stable `code`, rule,
/// event index, and human-readable message. JSON string escaping is delegated
/// to MoonBit's standard `Json::stringify` implementation.
pub fn scenario_results_json(results : Array[ScenarioResult]) -> String {
  let report = Json::array(
    results.map(result => {
      Json::object({
        "name": Json(result.name),
        "passed": Json(result.passed),
        "violations": Json::array(
          result.violations.map(violation => {
            Json::object({
              "code": Json(violation_code(violation)),
              "rule": Json(violation.rule),
              "event_index": Json(violation.event_index),
              "message": Json(violation.message),
            })
          }),
        ),
      })
    }),
  )
  report.stringify()
}

///|
/// Serialize the aggregate view used by CI gates and dashboards.
pub fn suite_summary_json(summary : SuiteSummary) -> String {
  Json::object({
    "scenario_count": Json(summary.scenario_count),
    "passed_count": Json(summary.passed_count),
    "failed_count": Json(summary.failed_count),
    "violation_count": Json(summary.violation_count),
    "rules": Json::array(
      summary.rules.map(rule => {
        Json::object({
          "code": Json(rule.code),
          "rule": Json(rule.rule),
          "count": Json(rule.count),
        })
      }),
    ),
  }).stringify()
}
