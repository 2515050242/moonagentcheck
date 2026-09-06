///|
/// Evaluate a deterministic event sequence against basic tool-call contracts.
pub fn evaluate(events : Array[Event], max_retries : Int) -> Array[Violation] {
  let violations : Array[Violation] = []
  let pending : Array[String] = []
  let attempts : Map[String, Int] = {}
  let completed : Map[String, Bool] = {}
  for index, event in events {
    if event.kind == "call" {
      pending.push(event.call_id)
      match event.operation_id {
        Some(operation) => {
          let count = match attempts[operation] { Some(value) => value + 1; None => 1 }
          attempts[operation] = count
          if count > max_retries {
            violations.push({ rule: "retry-limit", event_index: index, message: operation })
          }
        }
        None => ()
      }
    } else if event.kind == "result" {
      if !pending.contains(event.call_id) {
        violations.push({ rule: "orphan-result", event_index: index, message: event.call_id })
      }
    } else if event.kind == "write-complete" {
      match event.operation_id {
        Some(operation) => {
          if completed[operation] is Some(true) {
            violations.push({ rule: "duplicate-side-effect", event_index: index, message: operation })
          }
          completed[operation] = true
        }
        None => ()
      }
    }
  }
  violations
}

