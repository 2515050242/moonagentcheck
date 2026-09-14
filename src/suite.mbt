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
  let results : Array[ScenarioResult] = []
  for scenario in scenarios {
    let violations = evaluate(scenario.events, max_retries)
    results.push({
      name: scenario.name,
      passed: violations.length() == 0,
      violations,
    })
  }
  results
}
