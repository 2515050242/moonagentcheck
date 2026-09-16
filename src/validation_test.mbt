///|
test "preflight catches malformed event fields and unknown kinds" {
  let events = [Event::new("callback", "", "", None, None)]
  let violations = validate_events(events, 2)
  assert_true(violations.length() == 3)
  assert_true(violations[0].rule == "unknown-event-kind")
  assert_true(violations[1].rule == "invalid-event")
  assert_true(violations[2].rule == "invalid-event")
  assert_true(violation_code(violations[0]) == "AGC014")
}

///|
test "evaluation reports negative retry policy" {
  let violations = evaluate([], -1)
  assert_true(violations.length() == 1)
  assert_true(violations[0].rule == "invalid-policy")
  assert_true(violation_code(violations[0]) == "AGC015")
}
