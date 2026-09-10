///|
/// An observation emitted by an agent adapter.
pub struct Event {
  kind : String
  tool : String
  call_id : String
  operation_id : String?
  /// Whether the tool reported success. A reported failure is a contract violation.
  ok : Bool?
} derive(Debug, Eq)

pub fn Event::new(
  kind : String,
  tool : String,
  call_id : String,
  operation_id : String?,
  ok : Bool?,
) -> Event {
  { kind, tool, call_id, operation_id, ok }
}

///|
/// A single contract failure. The first event that violates a rule is reported.
pub struct Violation {
  rule : String
  event_index : Int
  message : String
} derive(Debug, Eq)
