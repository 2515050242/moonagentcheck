///|
/// An observation emitted by an agent adapter.
#derive(Debug, Eq)
pub struct Event {
  kind : String
  tool : String
  call_id : String
  operation_id : String?
  /// Whether the tool reported success. A reported failure is a contract violation.
  ok : Bool?
}

///|
pub fn Event::new(
  kind : String,
  tool : String,
  call_id : String,
  operation_id : String?,
  ok : Bool?,
) -> Event {
  { kind, tool, call_id, operation_id, ok, }
}

///|
/// A single contract failure. The first event that violates a rule is reported.
#derive(Debug, Eq)
pub struct Violation {
  rule : String
  event_index : Int32
  message : String
}

///|
/// Configuration for an evaluation run.
///
/// When `tool_allowlist` is `None`, calls to every tool are permitted. An
/// explicit empty allowlist permits no tools.
pub struct EvaluationPolicy {
  max_retries : Int32
  tool_allowlist : Array[String]?
}

///|
pub fn EvaluationPolicy::new(
  max_retries : Int32,
  tool_allowlist : Array[String]?,
) -> EvaluationPolicy {
  { max_retries, tool_allowlist, }
}
