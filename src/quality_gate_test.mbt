///|
test "quality gate passes a clean event stream" {
  let gate = QualityGate::for_library().with_violation_budget(0)
  let events = [
    Event::new("call", "read", "c1", Some("read"), None),
    Event::new("result", "read", "c1", Some("read"), Some(true)),
  ]
  let decision = gate.check_events(
    events,
    EvaluationPolicy::new(1, Some(["read"])),
  )
  assert_true(decision.passed)
  assert_true(decision.score == 100)
  assert_true(decision.failed_reasons().length() == 0)
}

///|
test "quality gate explains why a malformed stream fails" {
  let gate = QualityGate::for_library()
  let decision = gate.check_events(
    [Event::new("result", "", "", None, Some(true))],
    EvaluationPolicy::new(0, None),
  )
  assert_true(!decision.passed)
  assert_true(decision.failed_reasons().length() > 0)
  assert_true(decision.render().contains("fail"))
  assert_true(gate_decision_json(decision).contains("passed"))
}

///|
test "quality gate can require named scenarios" {
  let results = evaluate_scenarios(
    [Scenario::new("required", []), Scenario::new("optional", [])],
    2,
  )
  let gate = QualityGate::for_regression().requiring(["required"])
  let decision = gate.check_suite(results)
  assert_true(decision.passed)
  let missing = QualityGate::for_regression()
    .requiring(["missing"])
    .check_suite(results)
  assert_true(!missing.passed)
  let allowed = QualityGate::for_regression().allow_failed_scenarios()
  assert_true(allowed.require_successful_scenarios == false)
}

///|
test "policy gates align with explicit read-only policy" {
  let policy = EvaluationPolicy::new(
    1,
    Some(["read_file", "read_csv", "list_files"]),
  )
  assert_true(
    QualityGate::for_library().check_events(
      [
        Event::new("call", "read_file", "c1", Some("read"), None),
        Event::new("result", "read_file", "c1", Some("read"), Some(true)),
      ],
      policy,
    ).passed,
  )
  assert_true(
    !QualityGate::for_library().check_events(
      [Event::new("call", "delete_file", "c1", Some("delete"), None)],
      policy,
    ).passed,
  )
}
