///|
/// Validate fields that an adapter must provide before contract evaluation.
/// This is deliberately separate from semantic rules such as retry limits.
pub fn validate_events(
  events : Array[Event],
  max_retries : Int,
) -> Array[Violation] {
  let violations : Array[Violation] = []
  if max_retries < 0 {
    violations.push({
      rule: "invalid-policy",
      event_index: -1,
      message: "max_retries must be non-negative",
    })
  }
  for index, event in events {
    if event.kind != "call" &&
      event.kind != "result" &&
      event.kind != "write-complete" {
      violations.push({
        rule: "unknown-event-kind",
        event_index: index,
        message: event.kind,
      })
    }
    if event.call_id == "" {
      violations.push({
        rule: "invalid-event",
        event_index: index,
        message: "call_id is empty",
      })
    }
    if event.tool == "" {
      violations.push({
        rule: "invalid-event",
        event_index: index,
        message: "tool is empty",
      })
    }
  }
  violations
}
