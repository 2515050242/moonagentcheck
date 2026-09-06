///|
test "detects duplicate side effect" {
  let events = [
    Event::new("write-complete", "ticket", "1", Some("reply-42"), Some(true)),
    Event::new("write-complete", "ticket", "2", Some("reply-42"), Some(true)),
  ]
  let report = evaluate(events, 2)
  assert_true(report.length() == 1)
  assert_true(report[0].rule == "duplicate-side-effect")
}
