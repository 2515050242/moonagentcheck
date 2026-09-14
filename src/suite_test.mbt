///|
test "evaluates named scenarios independently and preserves order" {
  let scenarios = [
    Scenario::new("read-ok", [
      Event::new("call", "read_file", "same-id", Some("read"), None),
      Event::new("result", "read_file", "same-id", Some("read"), Some(true)),
    ]),
    Scenario::new("orphan-result", [
      Event::new("result", "read_file", "same-id", Some("read"), Some(true)),
    ]),
  ]
  let results = evaluate_scenarios(scenarios, 2)
  assert_true(results.length() == 2)
  assert_true(results[0].name == "read-ok")
  assert_true(results[0].passed)
  assert_true(results[0].violations.length() == 0)
  assert_true(results[1].name == "orphan-result")
  assert_true(!results[1].passed)
  assert_true(results[1].violations[0].rule == "orphan-result")
}

///|
test "empty scenario suite produces an empty result" {
  assert_true(evaluate_scenarios([], 2).length() == 0)
}
