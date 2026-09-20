///|
/// Selects how a suite runner obtains its scenarios.
pub enum RunMode {
  AllScenarios
  NamedScenarios
  TaggedScenarios
  SingleTrace
} derive(Eq, Debug)

///|
pub fn run_mode_name(mode : RunMode) -> String {
  match mode {
    AllScenarios => "all"
    NamedScenarios => "named"
    TaggedScenarios => "tagged"
    SingleTrace => "single"
  }
}

///|
pub struct RunConfig {
  name : String
  mode : RunMode
  max_retries : Int
  policy : EvaluationPolicy
  names : Array[String]
  tag : String?
}

///|
pub fn RunConfig::new(name : String, policy : EvaluationPolicy) -> RunConfig {
  {
    name,
    mode: AllScenarios,
    max_retries: policy.max_retries,
    policy,
    names: [],
    tag: None,
  }
}

///|
pub fn RunConfig::all(name : String, policy : EvaluationPolicy) -> RunConfig {
  RunConfig::new(name, policy)
}

///|
pub fn RunConfig::named(
  name : String,
  policy : EvaluationPolicy,
  names : Array[String],
) -> RunConfig {
  {
    ..RunConfig::new(name, policy),
    mode: NamedScenarios,
    names: unique_strings(names),
  }
}

///|
pub fn RunConfig::tagged(
  name : String,
  policy : EvaluationPolicy,
  tag : String,
) -> RunConfig {
  { ..RunConfig::new(name, policy), mode: TaggedScenarios, tag: Some(tag), }
}

///|
pub fn RunConfig::with_retry_limit(
  config : RunConfig,
  max_retries : Int,
) -> RunConfig {
  {
    ..config,
    max_retries,
    policy: policy_with_max_retries(config.policy, max_retries),
  }
}

///|
pub fn RunConfig::mode_name(config : RunConfig) -> String {
  run_mode_name(config.mode)
}

///|
pub fn RunConfig::describe(config : RunConfig) -> String {
  let selector = match config.mode {
    AllScenarios => "all"
    NamedScenarios => config.names.join(",")
    TaggedScenarios =>
      match config.tag {
        Some(tag) => "tag=" + tag
        None => "tag=?"
      }
    SingleTrace => "single"
  }
  config.name +
  " mode=" +
  config.mode_name() +
  " selector=" +
  selector +
  " retries=" +
  config.max_retries.to_string()
}

///|
pub struct RunOutcome {
  run_name : String
  mode : RunMode
  results : Array[ScenarioResult]
  summary : SuiteSummary
  diagnostics : Array[Diagnostic]
  gate : GateDecision
}

///|
pub fn RunOutcome::passed(outcome : RunOutcome) -> Bool {
  outcome.gate.passed
}

///|
pub fn RunOutcome::failed_names(outcome : RunOutcome) -> Array[String] {
  outcome.results.filter(result => !result.passed).map(result => result.name)
}

///|
pub fn RunOutcome::passed_names(outcome : RunOutcome) -> Array[String] {
  outcome.results.filter(result => result.passed).map(result => result.name)
}

///|
pub fn RunOutcome::diagnostic_codes(outcome : RunOutcome) -> Array[String] {
  diagnostic_codes(outcome.diagnostics)
}

///|
pub fn RunOutcome::render(outcome : RunOutcome) -> String {
  outcome.run_name +
  " " +
  run_mode_name(outcome.mode) +
  " " +
  outcome.summary.violation_count.to_string() +
  " violations\n" +
  outcome.gate.render()
}

///|
pub fn RunOutcome::json(outcome : RunOutcome) -> String {
  Json::object({
    "run": Json(outcome.run_name),
    "mode": Json(run_mode_name(outcome.mode)),
    "passed": Json(outcome.passed()),
    "scenario_count": Json(outcome.summary.scenario_count),
    "passed_count": Json(outcome.summary.passed_count),
    "failed_count": Json(outcome.summary.failed_count),
    "violation_count": Json(outcome.summary.violation_count),
    "diagnostics": Json::array(
      outcome.diagnostics.map(diagnostic => {
        Json::object({
          "code": Json(diagnostic.code),
          "rule": Json(diagnostic.rule),
          "severity": Json(diagnostic.severity_name()),
          "event_index": Json(diagnostic.event_index),
          "message": Json(diagnostic.message),
        })
      }),
    ),
    "gate": Json::object({
      "passed": Json(outcome.gate.passed),
      "score": Json(outcome.gate.score),
      "reasons": Json::array(
        outcome.gate.reasons.map(reason => {
          Json::object({
            "code": Json(reason.code),
            "passed": Json(reason.passed),
            "message": Json(reason.message),
          })
        }),
      ),
    }),
  }).stringify()
}

///|
pub struct RunRecord {
  sequence : Int
  run_name : String
  mode : RunMode
  passed : Bool
  violation_count : Int
  diagnostic_count : Int
}

///|
pub fn RunRecord::render(record : RunRecord) -> String {
  let status = if record.passed { "passed" } else { "failed" }
  "#" +
  record.sequence.to_string() +
  " " +
  record.run_name +
  " " +
  status +
  " violations=" +
  record.violation_count.to_string()
}

///|
pub struct SuiteRunner {
  catalog : ScenarioCatalog
  history : Array[RunRecord]
  next_sequence_state : Array[Int]
}

///|
pub fn SuiteRunner::new(catalog : ScenarioCatalog) -> SuiteRunner {
  { catalog, history: [], next_sequence_state: [1], }
}

///|
pub fn SuiteRunner::catalog(runner : SuiteRunner) -> ScenarioCatalog {
  runner.catalog
}

///|
pub fn SuiteRunner::history(runner : SuiteRunner) -> Array[RunRecord] {
  runner.history
}

///|
pub fn SuiteRunner::history_len(runner : SuiteRunner) -> Int {
  runner.history.length()
}

///|
pub fn SuiteRunner::last_record(runner : SuiteRunner) -> RunRecord? {
  if runner.history.length() == 0 {
    None
  } else {
    Some(runner.history[runner.history.length() - 1])
  }
}

///|
fn scenarios_for_config(
  catalog : ScenarioCatalog,
  config : RunConfig,
) -> Array[Scenario] {
  match config.mode {
    AllScenarios => catalog.scenarios()
    NamedScenarios => catalog.select(config.names).map(entry => entry.scenario)
    TaggedScenarios =>
      match config.tag {
        Some(tag) => catalog.scenarios_with_tag(tag)
        None => []
      }
    SingleTrace => []
  }
}

///|
fn outcome_diagnostics(results : Array[ScenarioResult]) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  for result in results {
    for violation in result.violations {
      diagnostics.push(diagnostic_from_violation(violation))
    }
  }
  diagnostics
}

///|
fn record_for_outcome(sequence : Int, outcome : RunOutcome) -> RunRecord {
  {
    sequence,
    run_name: outcome.run_name,
    mode: outcome.mode,
    passed: outcome.passed(),
    violation_count: outcome.summary.violation_count,
    diagnostic_count: outcome.diagnostics.length(),
  }
}

///|
pub fn SuiteRunner::run(runner : SuiteRunner, config : RunConfig) -> RunOutcome {
  let scenarios = scenarios_for_config(runner.catalog, config)
  let results = evaluate_scenarios_with_policy(scenarios, config.policy)
  let summary = summarize_scenarios(results)
  let diagnostics = outcome_diagnostics(results)
  let gate = QualityGate::for_regression().check_suite(results)
  let outcome = {
    run_name: config.name,
    mode: config.mode,
    results,
    summary,
    diagnostics,
    gate,
  }
  runner.history.push(
    record_for_outcome(runner.next_sequence_state[0], outcome),
  )
  runner.next_sequence_state[0] = runner.next_sequence_state[0] + 1
  outcome
}

///|
pub fn SuiteRunner::run_all(
  runner : SuiteRunner,
  name : String,
  policy : EvaluationPolicy,
) -> RunOutcome {
  runner.run(RunConfig::all(name, policy))
}

///|
pub fn SuiteRunner::run_names(
  runner : SuiteRunner,
  name : String,
  policy : EvaluationPolicy,
  names : Array[String],
) -> RunOutcome {
  runner.run(RunConfig::named(name, policy, names))
}

///|
pub fn SuiteRunner::run_tag(
  runner : SuiteRunner,
  name : String,
  policy : EvaluationPolicy,
  tag : String,
) -> RunOutcome {
  runner.run(RunConfig::tagged(name, policy, tag))
}

///|
pub fn SuiteRunner::run_events(
  runner : SuiteRunner,
  name : String,
  events : Array[Event],
  policy : EvaluationPolicy,
) -> RunOutcome {
  let scenario = Scenario::new(name, events)
  let results = evaluate_scenarios_with_policy([scenario], policy)
  let summary = summarize_scenarios(results)
  let diagnostics = outcome_diagnostics(results)
  let gate = QualityGate::for_library().check_events(events, policy)
  let outcome = {
    run_name: name,
    mode: SingleTrace,
    results,
    summary,
    diagnostics,
    gate,
  }
  runner.history.push(
    record_for_outcome(runner.next_sequence_state[0], outcome),
  )
  runner.next_sequence_state[0] = runner.next_sequence_state[0] + 1
  outcome
}

///|
pub fn SuiteRunner::clear_history(runner : SuiteRunner) -> Unit {
  while runner.history.length() > 0 {
    let _ = runner.history.pop()
  }
  runner.next_sequence_state[0] = 1
}

///|
pub fn SuiteRunner::history_render(runner : SuiteRunner) -> String {
  runner.history.map(record => record.render()).join("\n")
}

///|
pub fn SuiteRunner::history_json(runner : SuiteRunner) -> String {
  Json::array(
    runner.history.map(record => {
      Json::object({
        "sequence": Json(record.sequence),
        "run": Json(record.run_name),
        "mode": Json(run_mode_name(record.mode)),
        "passed": Json(record.passed),
        "violation_count": Json(record.violation_count),
        "diagnostic_count": Json(record.diagnostic_count),
      })
    }),
  ).stringify()
}

///|
pub fn run_config_json(config : RunConfig) -> String {
  let tag = match config.tag {
    Some(value) => Json(value)
    None => Json::null()
  }
  Json::object({
    "name": Json(config.name),
    "mode": Json(config.mode_name()),
    "max_retries": Json(config.max_retries),
    "names": Json::array(config.names.map(name => Json(name))),
    "tag": tag,
    "policy_max_retries": Json(config.policy.max_retries),
    "policy_restricted": Json(policy_is_restricted(config.policy)),
  }).stringify()
}

///|
pub fn run_outcomes_passed(outcomes : Array[RunOutcome]) -> Bool {
  outcomes.all(outcome => outcome.passed())
}

///|
pub fn run_outcomes_failed_names(outcomes : Array[RunOutcome]) -> Array[String] {
  outcomes.filter(outcome => !outcome.passed()).map(outcome => outcome.run_name)
}

///|
pub fn run_outcomes_summary(outcomes : Array[RunOutcome]) -> SuiteSummary {
  let scenarios : Array[ScenarioResult] = []
  for outcome in outcomes {
    for result in outcome.results {
      scenarios.push(result)
    }
  }
  summarize_scenarios(scenarios)
}
