///|
/// A named, independent event trace for a repeatable contract test.
pub struct Scenario {
  name : String
  events : Array[Event]
}

///|
pub fn Scenario::new(name : String, events : Array[Event]) -> Scenario {
  { name, events, }
}

///|
/// The result of evaluating one scenario. A clean trace has no violations.
pub struct ScenarioResult {
  name : String
  passed : Bool
  violations : Array[Violation]
}

///|
/// Evaluate each named trace independently, preserving input order and labels.
pub fn evaluate_scenarios(
  scenarios : Array[Scenario],
  max_retries : Int,
) -> Array[ScenarioResult] {
  evaluate_scenarios_with_policy(
    scenarios,
    EvaluationPolicy::new(max_retries, None),
  )
}

///|
/// Evaluate each named trace independently with the same retry and tool policy.
///
/// This is the policy-aware counterpart of `evaluate_scenarios`. Every scenario
/// receives the complete policy, so a restricted suite cannot accidentally skip
/// allowlist checks while retaining the input order and scenario labels.
pub fn evaluate_scenarios_with_policy(
  scenarios : Array[Scenario],
  policy : EvaluationPolicy,
) -> Array[ScenarioResult] {
  let results : Array[ScenarioResult] = []
  for scenario in scenarios {
    let violations = evaluate_with_policy(scenario.events, policy)
    results.push({
      name: scenario.name,
      passed: violations.length() == 0,
      violations,
    })
  }
  results
}
