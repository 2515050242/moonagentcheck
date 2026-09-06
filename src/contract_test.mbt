///|
test "detects duplicate side effect" {
  let events = [
    { kind: "write-complete", tool: "ticket", call_id: "1", operation_id: Some("reply-42"), ok: Some(true) },
    { kind: "write-complete", tool: "ticket", call_id: "2", operation_id: Some("reply-42"), ok: Some(true) },
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "duplicate-side-effect")
}

