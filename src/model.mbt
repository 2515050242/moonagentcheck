///|
/// An observation emitted by an agent adapter.
pub struct Event {
  kind : String
  tool : String
  call_id : String
  operation_id : String?
  ok : Bool?
} derive(Debug, Eq)

///|
/// A single contract failure. The first event that violates a rule is reported.
pub struct Violation {
  rule : String
  event_index : Int
  message : String
} derive(Debug, Eq)
