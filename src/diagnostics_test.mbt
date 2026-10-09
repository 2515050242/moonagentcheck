///|
test "diagnostics classify rules and provide actionable advice" {
  let diagnostics = @src.diagnose(
    [
      @src.Event::new("result", "read", "orphan", Some("read"), Some(true)),
      @src.Event::new("call", "write", "write", Some("save"), None),
    ],
    2,
  )
  assert_true(@src.diagnostic_count(diagnostics) == 2)
  assert_true(diagnostics[0].code == "AGC001")
  assert_true(diagnostics[0].severity_name() == "warning")
  assert_true(diagnostics[1].rule == "missing-result")
  assert_true(!@src.has_errors(diagnostics))
  assert_true(@src.has_warnings(diagnostics))
  assert_true(@src.advice_for_rule("write-without-call").length() > 0)
}

///|
test "diagnostic summaries separate error warning and info" {
  let diagnostics = @src.diagnose(
    [@src.Event::new("callback", "", "", None, None)],
    2,
  )
  let summary = @src.summarize_diagnostics(diagnostics)
  assert_true(summary.total == 3)
  assert_true(summary.errors == 3)
  assert_true(summary.warnings == 0)
  assert_true(summary.infos == 0)
  assert_true(!summary.passed())
  match @src.first_error(diagnostics) {
    Some(_) => ()
    None => assert_true(false)
  }
  assert_true(@src.diagnostics_are_ordered(diagnostics))
}

///|
test "unknown result is an error that prevents a passing summary" {
  let diagnostics = @src.diagnose(
    [
      @src.Event::new(
        "call",
        "update_ticket",
        "call-unknown",
        Some("ticket-1"),
        None,
      ),
      @src.Event::new(
        "result",
        "update_ticket",
        "call-unknown",
        Some("ticket-1"),
        None,
      ),
    ],
    1,
  )
  let summary = @src.summarize_diagnostics(diagnostics)
  assert_true(diagnostics.length() == 1)
  assert_true(diagnostics[0].code == "AGC018")
  assert_true(diagnostics[0].severity_name() == "error")
  assert_true(summary.errors == 1)
  assert_true(!summary.passed())
}

///|
test "diagnostics preserve codes and render machine readable JSON" {
  let diagnostics = @src.diagnose(
    [@src.Event::new("call", "read", "c1", None, None)],
    0,
  )
  assert_true(@src.diagnostic_codes(diagnostics) == ["AGC002"])
  assert_true(@src.diagnostic_rules(diagnostics) == ["missing-result"])
  assert_true(@src.diagnostic_event_indices(diagnostics) == [0])
  assert_true(@src.diagnostics_json(diagnostics).contains("AGC002"))
  assert_true(
    @src.diagnostic_message_for_code("AGC015") == "策略参数非法",
  )
}

///|
test "scenario diagnostics keep scenario labels" {
  let scenarios = @src.diagnose_scenarios(
    [
      @src.Scenario::new("ok", []),
      @src.Scenario::new("bad", [
        @src.Event::new("result", "read", "r", None, Some(true)),
      ]),
    ],
    2,
  )
  assert_true(scenarios.length() == 2)
  assert_true(scenarios[0].summary.passed())
  assert_true(scenarios[1].summary.total == 1)
  assert_true(
    @src.diagnostic_severity_name(scenarios[1].summary.highest) == "warning",
  )
  assert_true(@src.scenario_diagnostics_json(scenarios).contains("bad"))
}
