///|
priv enum ResultState {
  Pending
  Succeeded
  Failed
  Unknown
} derive(Eq)

///|
/// Evaluate a deterministic event sequence against basic tool-call contracts.
pub fn evaluate(events : Array[Event], max_retries : Int) -> Array[Violation] {
  let violations : Array[Violation] = []
  let pending : Array[String] = []
  let calls : Map[String, Event] = Map([])
  let attempts : Map[String, Int] = Map([])
  let completed : Map[String, Bool] = Map([])
  let resolved : Map[String, ResultState] = Map([])
  for index, event in events {
    if event.kind == "call" {
      if calls.get(event.call_id) is Some(_) {
        violations.push({
          rule: "duplicate-call-id",
          event_index: index,
          message: event.call_id,
        })
      }
      pending.push(event.call_id)
      calls[event.call_id] = event
      resolved[event.call_id] = Pending
      match event.operation_id {
        Some(operation) => {
          let count = match attempts.get(operation) {
            Some(value) => value + 1
            None => 1
          }
          attempts[operation] = count
          if count > max_retries {
            violations.push({
              rule: "retry-limit",
              event_index: index,
              message: operation,
            })
          }
        }
        None => ()
      }
    } else if event.kind == "result" {
      match calls.get(event.call_id) {
        None =>
          violations.push({
            rule: "orphan-result",
            event_index: index,
            message: event.call_id,
          })
        Some(_) =>
          if resolved.get(event.call_id) is Some(state) && state != Pending {
            violations.push({
              rule: "duplicate-result",
              event_index: index,
              message: event.call_id,
            })
          } else {
            let state = match event.ok {
              Some(true) => Succeeded
              Some(false) => Failed
              None => Unknown
            }
            resolved[event.call_id] = state
            if state == Failed {
              violations.push({
                rule: "failed-result",
                event_index: index,
                message: event.call_id,
              })
            }
          }
      }
    } else if event.kind == "write-complete" {
      if !pending.contains(event.call_id) {
        violations.push({
          rule: "write-without-call",
          event_index: index,
          message: event.call_id,
        })
      } else if (match resolved.get(event.call_id) {
          Some(Succeeded) => false
          Some(Pending) => true
          Some(Failed) => true
          Some(Unknown) => true
          None => true
        }) {
        violations.push({
          rule: "write-without-successful-result",
          event_index: index,
          message: event.call_id,
        })
      }
      match event.operation_id {
        Some(operation) => {
          if completed.get(operation) is Some(true) {
            violations.push({
              rule: "duplicate-side-effect",
              event_index: index,
              message: operation,
            })
          }
          completed[operation] = true
        }
        None =>
          violations.push({
            rule: "missing-operation-id",
            event_index: index,
            message: event.call_id,
          })
      }
    }
  }
  for index, call_id in pending {
    if resolved.get(call_id) is Some(Pending) {
      violations.push({
        rule: "missing-result",
        event_index: index,
        message: call_id,
      })
    }
  }
  violations
}
