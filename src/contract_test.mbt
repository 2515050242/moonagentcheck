///|
test "detects duplicate side effect" {
  let events = [
    Event::new("call", "ticket", "call-1", Some("reply-42"), None),
    Event::new("result", "ticket", "call-1", Some("reply-42"), Some(true)),
    Event::new("write-complete", "ticket", "call-1", Some("reply-42"), Some(true)),
    Event::new("write-complete", "ticket", "call-1", Some("reply-42"), Some(true)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "duplicate-side-effect")
}

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

test "enforces retry limit" {
  let events = [
    Event::new("call", "ticket", "call-1", Some("reply"), None),
    Event::new("result", "ticket", "call-1", Some("reply"), Some(false)),
    Event::new("call", "ticket", "call-2", Some("reply"), None),
  ]
  let report = evaluate(events, 1)
  assert_true(report.length() == 2)
  assert_true(report[0].rule == "retry-limit")
  assert_true(report[1].rule == "missing-result")
}

test "requires a call before a write" {
  let events = [
    Event::new("write-complete", "repo", "write-1", Some("edit"), Some(true)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "write-without-call")
}

test "accepts a completed call" {
  let events = [
    Event::new("call", "data", "call-1", Some("load"), None),
    Event::new("result", "data", "call-1", Some("load"), Some(true)),
  ]
  assert_true(evaluate(events, 2).length() == 0)
}

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
