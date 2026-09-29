///|
test "analysis filters and groups violations deterministically" {
  let events = [
    @src.Event::new("result", "data", "orphan-1", Some("load"), Some(true)),
    @src.Event::new("result", "data", "orphan-2", Some("load"), Some(true)),
  ]
  let violations = @src.evaluate(events, 2)
  assert_true(@src.count_rule(violations, "orphan-result") == 2)
  assert_true(@src.violations_for(violations, "orphan-result").length() == 2)
  let summaries = @src.summarize_violations(violations)
  assert_true(summaries.length() == 1)
  assert_true(summaries[0].code == "AGC001")
  assert_true(summaries[0].count == 2)
}

///|
test "suite summary counts passed failed and rules" {
  let results = @src.evaluate_scenarios(
    [
      @src.Scenario::new("ok", [
        @src.Event::new("call", "data", "c1", Some("load"), None),
        @src.Event::new("result", "data", "c1", Some("load"), Some(true)),
      ]),
      @src.Scenario::new("bad", [
        @src.Event::new("result", "data", "r1", Some("load"), Some(true)),
      ]),
    ],
    2,
  )
  let summary = @src.summarize_scenarios(results)
  assert_true(summary.scenario_count == 2)
  assert_true(summary.passed_count == 1)
  assert_true(summary.failed_count == 1)
  assert_true(summary.violation_count == 1)
  assert_true(summary.rules[0].rule == "orphan-result")
  assert_true(
    @src.suite_summary_json(summary) ==
    "{\"scenario_count\":2,\"passed_count\":1,\"failed_count\":1,\"violation_count\":1,\"rules\":[{\"code\":\"AGC001\",\"rule\":\"orphan-result\",\"count\":1}]}",
  )
}
