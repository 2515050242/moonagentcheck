///|
test "detects duplicate side effect" {
  let events = [
    Event::new("call", "ticket", "call-1", Some("reply-42"), None),
    Event::new("result", "ticket", "call-1", Some("reply-42"), Some(true)),
    Event::new(
      "write-complete",
      "ticket",
      "call-1",
      Some("reply-42"),
      Some(true),
    ),
    Event::new(
      "write-complete",
      "ticket",
      "call-1",
      Some("reply-42"),
      Some(true),
    ),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "duplicate-side-effect")
}

///|
test "detects orphan and missing results" {
  let events = [
    Event::new("call", "data", "call-1", Some("load"), None),
    Event::new("result", "data", "unknown", Some("load"), Some(true)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 2)
  assert_true(report[0].rule == "orphan-result")
  assert_true(report[1].rule == "missing-result")
}

///|
test "enforces retry limit" {
  let events = [
    Event::new("call", "ticket", "call-1", Some("reply"), None),
    Event::new("result", "ticket", "call-1", Some("reply"), Some(false)),
    Event::new("call", "ticket", "call-2", Some("reply"), None),
  ]
  let report = evaluate(events, 1)
  assert_true(report.length() == 3)
  assert_true(report[0].rule == "failed-result")
  assert_true(report[1].rule == "retry-limit")
  assert_true(report[2].rule == "missing-result")
}

///|
test "ticket retry writes back only once" {
  let events = [
    Event::new("call", "update_ticket", "ticket-1", Some("reply-42"), None),
    Event::new(
      "result",
      "update_ticket",
      "ticket-1",
      Some("reply-42"),
      Some(false),
    ),
    Event::new("call", "update_ticket", "ticket-2", Some("reply-42"), None),
    Event::new(
      "result",
      "update_ticket",
      "ticket-2",
      Some("reply-42"),
      Some(true),
    ),
    Event::new(
      "write-complete",
      "update_ticket",
      "ticket-2",
      Some("reply-42"),
      Some(true),
    ),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "failed-result")
}

///|
test "reports failed tool results" {
  let events = [
    Event::new("call", "data", "call-1", Some("load"), None),
    Event::new("result", "data", "call-1", Some("load"), Some(false)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "failed-result")
  assert_true(report[0].message == "call-1")
}

///|
test "data agent missing-column result stays failed" {
  let events = [
    Event::new("call", "read_csv", "csv-1", Some("inspect-columns"), None),
    Event::new(
      "result",
      "read_csv",
      "csv-1",
      Some("inspect-columns"),
      Some(false),
    ),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "failed-result")
  assert_true(violation_code(report[0]) == "AGC009")
}

///|
test "requires a call before a write" {
  let events = [
    Event::new("write-complete", "repo", "write-1", Some("edit"), Some(true)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "write-without-call")
}

///|
test "accepts a completed call" {
  let events = [
    Event::new("call", "data", "call-1", Some("load"), None),
    Event::new("result", "data", "call-1", Some("load"), Some(true)),
  ]
  assert_true(evaluate(events, 2).length() == 0)
}

///|
test "rejects a result whose tool does not match its call" {
  let events = [
    Event::new("call", "read_csv", "call-1", Some("load"), None),
    Event::new("result", "write_csv", "call-1", Some("load"), Some(true)),
    Event::new("write-complete", "read_csv", "call-1", Some("load"), Some(true)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 2)
  assert_true(report[0].rule == "result-call-mismatch")
  assert_true(violation_code(report[0]) == "AGC011")
  assert_true(report[1].rule == "write-without-successful-result")
}

///|
test "rejects a result whose operation does not match its call" {
  let events = [
    Event::new("call", "update_ticket", "call-1", Some("reply-42"), None),
    Event::new(
      "result",
      "update_ticket",
      "call-1",
      Some("reply-99"),
      Some(true),
    ),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "result-call-mismatch")
  assert_true(violation_code(report[0]) == "AGC011")
}

///|
test "accepts a result that matches its call metadata" {
  let events = [
    Event::new("call", "update_ticket", "call-1", Some("reply-42"), None),
    Event::new(
      "result",
      "update_ticket",
      "call-1",
      Some("reply-42"),
      Some(true),
    ),
  ]
  assert_true(evaluate(events, 2).length() == 0)
}

///|
test "detects duplicate call ids" {
  let events = [
    Event::new("call", "data", "call-1", Some("load"), None),
    Event::new("call", "data", "call-1", Some("load"), None),
    Event::new("result", "data", "call-1", Some("load"), Some(true)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "duplicate-call-id")
}

///|
test "detects duplicate results" {
  let events = [
    Event::new("call", "data", "call-1", Some("load"), None),
    Event::new("result", "data", "call-1", Some("load"), Some(true)),
    Event::new("result", "data", "call-1", Some("load"), Some(true)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "duplicate-result")
}

///|
test "requires an operation id for a write" {
  let events = [
    Event::new("call", "repo", "call-1", None, None),
    Event::new("result", "repo", "call-1", None, Some(true)),
    Event::new("write-complete", "repo", "call-1", None, Some(true)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "missing-operation-id")
}

///|
test "does not accept a write after a failed tool result" {
  let events = [
    Event::new("call", "update_ticket", "ticket-1", Some("reply-42"), None),
    Event::new(
      "result",
      "update_ticket",
      "ticket-1",
      Some("reply-42"),
      Some(false),
    ),
    Event::new(
      "write-complete",
      "update_ticket",
      "ticket-1",
      Some("reply-42"),
      Some(true),
    ),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 2)
  assert_true(report[0].rule == "failed-result")
  assert_true(report[1].rule == "write-without-successful-result")
  assert_true(violation_code(report[1]) == "AGC010")
}

///|
test "does not accept a write while the call result is unknown" {
  let events = [
    Event::new("call", "update_ticket", "ticket-1", Some("reply-42"), None),
    Event::new("result", "update_ticket", "ticket-1", Some("reply-42"), None),
    Event::new(
      "write-complete",
      "update_ticket",
      "ticket-1",
      Some("reply-42"),
      Some(true),
    ),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "write-without-successful-result")
}

///|
test "policy allows calls in its tool allowlist" {
  let events = [
    Event::new("call", "read_file", "call-1", Some("inspect"), None),
    Event::new("result", "read_file", "call-1", Some("inspect"), Some(true)),
  ]
  let policy = EvaluationPolicy::new(2, Some(["read_file"]))
  assert_true(evaluate_with_policy(events, policy).length() == 0)
}

///|
test "policy rejects disallowed tools and continues other checks" {
  let events = [Event::new("call", "write_file", "call-1", Some("write"), None)]
  let policy = EvaluationPolicy::new(2, Some(["read_file"]))
  let report = evaluate_with_policy(events, policy)
  assert_true(report.length() == 2)
  assert_true(report[0].rule == "tool-not-allowed")
  assert_true(violation_code(report[0]) == "AGC012")
  assert_true(report[1].rule == "missing-result")
}

///|
test "an empty tool allowlist rejects every tool" {
  let events = [
    Event::new("call", "read_file", "call-1", Some("inspect"), None),
    Event::new("result", "read_file", "call-1", Some("inspect"), Some(true)),
  ]
  let report = evaluate_with_policy(events, EvaluationPolicy::new(2, Some([])))
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "tool-not-allowed")
}

///|
test "legacy evaluate remains unrestricted" {
  let events = [
    Event::new("call", "unlisted_tool", "call-1", Some("inspect"), None),
    Event::new("result", "unlisted_tool", "call-1", Some("inspect"), Some(true)),
  ]
  assert_true(evaluate(events, 2).length() == 0)
}
