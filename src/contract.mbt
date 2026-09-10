///|
/// Evaluate a deterministic event sequence against basic tool-call contracts.
pub fn evaluate(events : Array[Event], max_retries : Int) -> Array[Violation] {
  let violations : Array[Violation] = []
  let pending : Array[String] = []
  let attempts : Map[String, Int] = Map([])
  let completed : Map[String, Bool] = Map([])
  let resolved : Map[String, Bool] = Map([])
  for index, event in events {
    if event.kind == "call" {
      if pending.contains(event.call_id) {
        violations.push({ rule: "duplicate-call-id", event_index: index, message: event.call_id })
      }
      pending.push(event.call_id)
      resolved[event.call_id] = false
      match event.operation_id {
        Some(operation) => {
          let count = match attempts.get(operation) { Some(value) => value + 1; None => 1 }
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
      } else if resolved.get(event.call_id) is Some(true) {
        violations.push({ rule: "duplicate-result", event_index: index, message: event.call_id })
      } else {
        resolved[event.call_id] = true
        if event.ok is Some(false) {
          violations.push({ rule: "failed-result", event_index: index, message: event.call_id })
        }
      }
    } else if event.kind == "write-complete" {
      match event.operation_id {
        Some(operation) => {
          if !pending.contains(event.call_id) {
            violations.push({ rule: "write-without-call", event_index: index, message: event.call_id })
          }
          if completed.get(operation) is Some(true) {
            violations.push({ rule: "duplicate-side-effect", event_index: index, message: operation })
          }
          completed[operation] = true
        }
        None => {
          violations.push({ rule: "missing-operation-id", event_index: index, message: event.call_id })
        }
      }
    }
  }
  for index, call_id in pending {
    if resolved.get(call_id) is Some(false) {
      violations.push({ rule: "missing-result", event_index: index, message: call_id })
    }
  }
  violations
}
