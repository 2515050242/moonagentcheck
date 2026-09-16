///|
test "diagnostics classify rules and provide actionable advice" {
  let diagnostics = diagnose(
    [
      Event::new("result", "read", "orphan", Some("read"), Some(true)),
      Event::new("call", "write", "write", Some("save"), None),
    ],
    2,
  )
  assert_true(diagnostic_count(diagnostics) == 2)
  assert_true(diagnostics[0].code == "AGC001")
  assert_true(diagnostics[0].severity_name() == "warning")
  assert_true(diagnostics[1].rule == "missing-result")
  assert_true(!has_errors(diagnostics))
  assert_true(has_warnings(diagnostics))
  assert_true(advice_for_rule("write-without-call").length() > 0)
}

///|
test "diagnostic summaries separate error warning and info" {
  let diagnostics = diagnose([Event::new("callback", "", "", None, None)], 2)
  let summary = summarize_diagnostics(diagnostics)
  assert_true(summary.total == 3)
  assert_true(summary.errors == 3)
  assert_true(summary.warnings == 0)
  assert_true(summary.infos == 0)
  assert_true(!summary.passed())
  match first_error(diagnostics) {
    Some(_) => ()
    None => assert_true(false)
  }
  assert_true(diagnostics_are_ordered(diagnostics))
}

///|
test "diagnostics preserve codes and render machine readable JSON" {
  let diagnostics = diagnose([Event::new("call", "read", "c1", None, None)], 0)
  assert_true(diagnostic_codes(diagnostics) == ["AGC002"])
  assert_true(diagnostic_rules(diagnostics) == ["missing-result"])
  assert_true(diagnostic_event_indices(diagnostics) == [0])
  assert_true(diagnostics_json(diagnostics).contains("AGC002"))
  assert_true(diagnostic_message_for_code("AGC015") == "策略参数非法")
}

///|
test "scenario diagnostics keep scenario labels" {
  let scenarios = diagnose_scenarios(
    [
      Scenario::new("ok", []),
      Scenario::new("bad", [Event::new("result", "read", "r", None, Some(true))]),
    ],
    2,
  )
  assert_true(scenarios.length() == 2)
  assert_true(scenarios[0].summary.passed())
  assert_true(scenarios[1].summary.total == 1)
  assert_true(
    diagnostic_severity_name(scenarios[1].summary.highest) == "warning",
  )
  assert_true(scenario_diagnostics_json(scenarios).contains("bad"))
}
