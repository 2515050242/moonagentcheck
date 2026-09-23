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
  evaluate_with_policy(events, EvaluationPolicy::new(max_retries, None))
}

///|
/// Evaluate an event sequence using retry and optional tool-permission policy.
pub fn evaluate_with_policy(
  events : Array[Event],
  policy : EvaluationPolicy,
) -> Array[Violation] {
  let violations : Array[Violation] = validate_events(
    events,
    policy.max_retries,
  )
  let pending : Array[String] = []
  let calls : Map[String, Event] = Map([])
  let attempts : Map[String, Int] = Map([])
  let completed : Map[String, Bool] = Map([])
  let resolved : Map[String, ResultState] = Map([])
  for index, event in events {
    if event.kind == "call" {
      match policy.tool_allowlist {
        Some(allowlist) =>
          if !allowlist.contains(event.tool) {
            violations.push({
              rule: "tool-not-allowed",
              event_index: index,
              message: event.tool,
            })
          }
        None => ()
      }
      if calls.get(event.call_id) is Some(_) {
        violations.push({
          rule: "duplicate-call-id",
          event_index: index,
          message: event.call_id,
        })
      } else {
        // Keep the first observation as the identity for this call. A duplicate
        // record must not replace its metadata and make a later result or write
        // appear valid for a different tool or logical operation.
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
            if count > policy.max_retries {
              violations.push({
                rule: "retry-limit",
                event_index: index,
                message: operation,
              })
            }
          }
          None => ()
        }
      }
    } else if event.kind == "result" {
      match calls.get(event.call_id) {
        None =>
          violations.push({
            rule: "orphan-result",
            event_index: index,
            message: event.call_id,
          })
        Some(call) =>
          if call.tool != event.tool || call.operation_id != event.operation_id {
            // A result with the right call ID but different metadata cannot
            // establish a successful call. Preserve that fact even if an
            // otherwise valid result appeared earlier in the stream.
            resolved[event.call_id] = Failed
            violations.push({
              rule: "result-call-mismatch",
              event_index: index,
              message: event.call_id,
            })
          } else if resolved.get(event.call_id) is Some(state) &&
            state != Pending {
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
      } else if calls.get(event.call_id) is Some(call) &&
        (call.tool != event.tool || call.operation_id != event.operation_id) {
        // A completion is evidence of the specific call that produced it.
        // Matching only call_id would allow a different tool or logical
        // operation to borrow a successful result from an unrelated write.
        violations.push({
          rule: "write-call-mismatch",
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
