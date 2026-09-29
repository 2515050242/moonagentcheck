///|
test "quality gate passes a clean event stream" {
  let gate = @src.QualityGate::for_library().with_violation_budget(0)
  let events = [
    @src.Event::new("call", "read", "c1", Some("read"), None),
    @src.Event::new("result", "read", "c1", Some("read"), Some(true)),
  ]
  let decision = gate.check_events(
    events,
    @src.EvaluationPolicy::new(1, Some(["read"])),
  )
  assert_true(decision.passed)
  assert_true(decision.score == 100)
  assert_true(decision.failed_reasons().length() == 0)
}

///|
test "quality gate explains why a malformed stream fails" {
  let gate = @src.QualityGate::for_library()
  let decision = gate.check_events(
    [@src.Event::new("result", "", "", None, Some(true))],
    @src.EvaluationPolicy::new(0, None),
  )
  assert_true(!decision.passed)
  assert_true(decision.failed_reasons().length() > 0)
  assert_true(decision.render().contains("fail"))
  assert_true(@src.gate_decision_json(decision).contains("passed"))
}

///|
test "quality gate can require named scenarios" {
  let results = @src.evaluate_scenarios(
    [@src.Scenario::new("required", []), @src.Scenario::new("optional", [])],
    2,
  )
  let gate = @src.QualityGate::for_regression().requiring(["required"])
  let decision = gate.check_suite(results)
  assert_true(decision.passed)
  let missing = @src.QualityGate::for_regression()
    .requiring(["missing"])
    .check_suite(results)
  assert_true(!missing.passed)
  let allowed = @src.QualityGate::for_regression().allow_failed_scenarios()
  assert_true(allowed.require_successful_scenarios == false)
}

///|
test "policy gates align with explicit read-only policy" {
  let policy = @src.EvaluationPolicy::new(
    1,
    Some(["read_file", "read_csv", "list_files"]),
  )
  assert_true(
    @src.QualityGate::for_library().check_events(
      [
        @src.Event::new("call", "read_file", "c1", Some("read"), None),
        @src.Event::new("result", "read_file", "c1", Some("read"), Some(true)),
      ],
      policy,
    ).passed,
  )
  assert_true(
    !@src.QualityGate::for_library().check_events(
      [@src.Event::new("call", "delete_file", "c1", Some("delete"), None)],
      policy,
    ).passed,
  )
}

///|
test "catalog gates retain the explicit policy" {
  let catalog = @src.ScenarioCatalog::new()
  assert_true(
    catalog.add_scenario(
      @src.Scenario::new("write", [
        @src.Event::new("call", "write_file", "w1", Some("write"), None),
        @src.Event::new("result", "write_file", "w1", Some("write"), Some(true)),
      ]),
      ["write"],
      "test",
      "write must be denied",
    ),
  )
  let gate = @src.QualityGate::for_library()
  let decision = gate.check_catalog_with_policy(
    catalog,
    @src.EvaluationPolicy::new(1, Some(["read_file"])),
  )
  assert_true(!decision.passed)
  assert_true(decision.diagnostics.length() == 1)
  assert_true(decision.diagnostics[0].code == "AGC012")
}
