///|
test "evaluates named scenarios independently and preserves order" {
  let scenarios = [
    @src.Scenario::new("read-ok", [
      @src.Event::new("call", "read_file", "same-id", Some("read"), None),
      @src.Event::new(
        "result",
        "read_file",
        "same-id",
        Some("read"),
        Some(true),
      ),
    ]),
    @src.Scenario::new("orphan-result", [
      @src.Event::new(
        "result",
        "read_file",
        "same-id",
        Some("read"),
        Some(true),
      ),
    ]),
  ]
  let results = @src.evaluate_scenarios(scenarios, 2)
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
  assert_true(@src.evaluate_scenarios([], 2).length() == 0)
}

///|
test "policy-aware scenarios preserve isolation and reject disallowed tools" {
  let scenarios = [
    @src.Scenario::new("read-ok", [
      @src.Event::new("call", "read_file", "read-1", Some("read"), None),
      @src.Event::new("result", "read_file", "read-1", Some("read"), Some(true)),
    ]),
    @src.Scenario::new("write-denied", [
      @src.Event::new("call", "write_file", "write-1", Some("write"), None),
      @src.Event::new(
        "result",
        "write_file",
        "write-1",
        Some("write"),
        Some(true),
      ),
    ]),
  ]
  let results = @src.evaluate_scenarios_with_policy(
    scenarios,
    @src.EvaluationPolicy::new(1, Some(["read_file"])),
  )
  assert_true(results.length() == 2)
  assert_true(results[0].passed)
  assert_true(!results[1].passed)
  assert_true(@src.violation_code(results[1].violations[0]) == "AGC012")
}
