///|
test "analysis filters and groups violations deterministically" {
  let events = [
    Event::new("result", "data", "orphan-1", Some("load"), Some(true)),
    Event::new("result", "data", "orphan-2", Some("load"), Some(true)),
  ]
  let violations = evaluate(events, 2)
  assert_true(count_rule(violations, "orphan-result") == 2)
  assert_true(violations_for(violations, "orphan-result").length() == 2)
  let summaries = summarize_violations(violations)
  assert_true(summaries.length() == 1)
  assert_true(summaries[0].code == "AGC001")
  assert_true(summaries[0].count == 2)
}

///|
test "suite summary counts passed failed and rules" {
  let results = evaluate_scenarios(
    [
      Scenario::new("ok", [
        Event::new("call", "data", "c1", Some("load"), None),
        Event::new("result", "data", "c1", Some("load"), Some(true)),
      ]),
      Scenario::new("bad", [
        Event::new("result", "data", "r1", Some("load"), Some(true)),
      ]),
    ],
    2,
  )
  let summary = summarize_scenarios(results)
  assert_true(summary.scenario_count == 2)
  assert_true(summary.passed_count == 1)
  assert_true(summary.failed_count == 1)
  assert_true(summary.violation_count == 1)
  assert_true(summary.rules[0].rule == "orphan-result")
  assert_true(
    suite_summary_json(summary) ==
    "{\"scenario_count\":2,\"passed_count\":1,\"failed_count\":1,\"violation_count\":1,\"rules\":[{\"code\":\"AGC001\",\"rule\":\"orphan-result\",\"count\":1}]}",
  )
}
