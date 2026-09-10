///|
test "maps evaluated violations to stable codes" {
  let events = [
    Event::new("call", "load", "call-1", None, None),
  ]
  let report = evaluate(events, 1)
  assert_true(violation_code(report[0]) == "AGC002")
}

test "returns unknown for an unrecognized rule" {
  assert_true(rule_code("adapter-specific-rule") == "unknown")
}
