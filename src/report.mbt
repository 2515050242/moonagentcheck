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
    _ => "unknown"
  }
}
