///|
test "suite runner selects all, names and tags" {
  let runner = SuiteRunner::new(builtin_scenario_catalog())
  let all = runner.run_all("all", EvaluationPolicy::new(2, None))
  assert_true(all.results.length() == 11)
  let named = runner.run_names("named", EvaluationPolicy::new(2, None), [
    "data-read-ok", "repository-read-ok",
  ])
  assert_true(named.results.length() == 2)
  let tagged = runner.run_tag(
    "ticket",
    EvaluationPolicy::new(2, None),
    "ticket",
  )
  assert_true(tagged.results.length() == 2)
  assert_true(runner.history_len() == 3)
  match runner.last_record() {
    Some(record) => assert_true(record.sequence == 3)
    None => assert_true(false)
  }
}

///|
test "suite runner supports one trace and keeps history JSON" {
  let runner = SuiteRunner::new(ScenarioCatalog::new())
  let outcome = runner.run_events(
    "single",
    [
      Event::new("call", "read", "c1", Some("read"), None),
      Event::new("result", "read", "c1", Some("read"), Some(true)),
    ],
    EvaluationPolicy::new(1, Some(["read"])),
  )
  assert_true(outcome.passed())
  assert_true(outcome.passed_names() == ["single"])
  assert_true(outcome.failed_names().length() == 0)
  assert_true(outcome.json().contains("single"))
  assert_true(runner.history_render().contains("#1"))
  assert_true(runner.history_json().contains("sequence"))
  runner.clear_history()
  assert_true(runner.history_len() == 0)
}

///|
test "run configurations describe selectors and aggregate outcomes" {
  let config = RunConfig::tagged(
    "ticket-run",
    EvaluationPolicy::new(2, None),
    "ticket",
  )
  assert_true(config.mode_name() == "tagged")
  assert_true(config.describe().contains("tag=ticket"))
  assert_true(run_config_json(config).contains("max_retries"))
  let runner = SuiteRunner::new(builtin_scenario_catalog())
  let one = runner.run(config)
  let two = runner.run_names("data", EvaluationPolicy::new(2, None), [
    "data-read-ok",
  ])
  assert_true(!run_outcomes_passed([one, two]))
  assert_true(run_outcomes_failed_names([one, two]).length() > 0)
  assert_true(run_outcomes_summary([two]).scenario_count == 1)
}
