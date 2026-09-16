///|
/// Count violations for one rule without changing their original order.
pub fn count_rule(violations : Array[Violation], rule : String) -> Int {
  let mut count = 0
  for violation in violations {
    if violation.rule == rule {
      count = count + 1
    }
  }
  count
}

///|
pub fn violations_for(
  violations : Array[Violation],
  rule : String,
) -> Array[Violation] {
  violations.filter(violation => violation.rule == rule)
}

///|
pub struct RuleSummary {
  rule : String
  code : String
  count : Int
}

///|
/// Group violations by rule, keeping the first-seen rule order for stable output.
pub fn summarize_violations(
  violations : Array[Violation],
) -> Array[RuleSummary] {
  let summaries : Array[RuleSummary] = []
  for violation in violations {
    let mut found = false
    for index, summary in summaries {
      if summary.rule == violation.rule {
        summaries[index] = {
          rule: summary.rule,
          code: summary.code,
          count: summary.count + 1,
        }
        found = true
      }
    }
    if !found {
      summaries.push({
        rule: violation.rule,
        code: violation_code(violation),
        count: 1,
      })
    }
  }
  summaries
}

///|
pub struct SuiteSummary {
  scenario_count : Int
  passed_count : Int
  failed_count : Int
  violation_count : Int
  rules : Array[RuleSummary]
}

///|
pub fn summarize_scenarios(results : Array[ScenarioResult]) -> SuiteSummary {
  let all_violations : Array[Violation] = []
  let mut passed_count = 0
  for result in results {
    if result.passed {
      passed_count = passed_count + 1
    }
    for violation in result.violations {
      all_violations.push(violation)
    }
  }
  {
    scenario_count: results.length(),
    passed_count,
    failed_count: results.length() - passed_count,
    violation_count: all_violations.length(),
    rules: summarize_violations(all_violations),
  }
}
