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
    _ => "unknown"
  }
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
