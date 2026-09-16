///|
/// A quality gate turns diagnostics into a deterministic CI decision. It is
/// intentionally small: it reports why a gate failed, but never hides the
/// underlying violations or pretends to be a security sandbox.
pub struct QualityGate {
  name : String
  max_errors : Int
  max_warnings : Int
  max_violations : Int
  required_scenarios : Array[String]
  require_successful_scenarios : Bool
}

///|
pub fn QualityGate::new(name : String) -> QualityGate {
  {
    name,
    max_errors: 0,
    max_warnings: 0,
    max_violations: 0,
    required_scenarios: [],
    require_successful_scenarios: true,
  }
}

///|
pub fn QualityGate::for_library() -> QualityGate {
  QualityGate::new("library-default")
}

///|
pub fn QualityGate::for_regression() -> QualityGate {
  {
    ..QualityGate::new("regression-default"),
    max_warnings: 3,
    max_violations: 3,
  }
}

///|
pub fn QualityGate::with_error_budget(
  gate : QualityGate,
  budget : Int,
) -> QualityGate {
  { ..gate, max_errors: if budget < 0 { 0 } else { budget }, }
}

///|
pub fn QualityGate::with_warning_budget(
  gate : QualityGate,
  budget : Int,
) -> QualityGate {
  { ..gate, max_warnings: if budget < 0 { 0 } else { budget }, }
}

///|
pub fn QualityGate::with_violation_budget(
  gate : QualityGate,
  budget : Int,
) -> QualityGate {
  { ..gate, max_violations: if budget < 0 { 0 } else { budget }, }
}

///|
pub fn QualityGate::requiring(
  gate : QualityGate,
  names : Array[String],
) -> QualityGate {
  { ..gate, required_scenarios: unique_strings(names), }
}

///|
pub fn QualityGate::allow_failed_scenarios(gate : QualityGate) -> QualityGate {
  { ..gate, require_successful_scenarios: false, }
}

///|
pub struct GateReason {
  code : String
  passed : Bool
  message : String
}

///|
pub fn GateReason::render(reason : GateReason) -> String {
  let status = if reason.passed { "pass" } else { "fail" }
  "[" + reason.code + "] " + status + ": " + reason.message
}

///|
pub struct GateDecision {
  gate_name : String
  passed : Bool
  score : Int
  reasons : Array[GateReason]
  diagnostics : Array[Diagnostic]
}

///|
pub fn GateDecision::is_passed(decision : GateDecision) -> Bool {
  decision.passed
}

///|
pub fn GateDecision::failed_reasons(
  decision : GateDecision,
) -> Array[GateReason] {
  decision.reasons.filter(reason => !reason.passed)
}

///|
pub fn GateDecision::render(decision : GateDecision) -> String {
  let lines : Array[String] = []
  lines.push(decision.gate_name + " score=" + decision.score.to_string())
  for reason in decision.reasons {
    lines.push(reason.render())
  }
  lines.join("\n")
}

///|
fn gate_reason(code : String, passed : Bool, message : String) -> GateReason {
  { code, passed, message, }
}

///|
fn gate_score(reasons : Array[GateReason]) -> Int {
  if reasons.length() == 0 {
    return 100
  }
  let mut passed = 0
  for reason in reasons {
    if reason.passed {
      passed = passed + 1
    }
  }
  passed * 100 / reasons.length()
}

///|
fn required_names_present(
  results : Array[ScenarioResult],
  required : Array[String],
) -> Bool {
  for name in required {
    let mut found = false
    for result in results {
      if result.name == name {
        found = true
      }
    }
    if !found {
      return false
    }
  }
  true
}

///|
fn all_required_passed(
  results : Array[ScenarioResult],
  required : Array[String],
) -> Bool {
  for name in required {
    for result in results {
      if result.name == name && !result.passed {
        return false
      }
    }
  }
  true
}

///|
fn gate_decision(
  gate : QualityGate,
  reasons : Array[GateReason],
  diagnostics : Array[Diagnostic],
) -> GateDecision {
  {
    gate_name: gate.name,
    passed: reasons.all(reason => reason.passed),
    score: gate_score(reasons),
    reasons,
    diagnostics,
  }
}

///|
pub fn QualityGate::check_diagnostics(
  gate : QualityGate,
  diagnostics : Array[Diagnostic],
) -> GateDecision {
  let reasons : Array[GateReason] = []
  let summary = summarize_diagnostics(diagnostics)
  reasons.push(
    gate_reason(
      "errors",
      summary.errors <= gate.max_errors,
      "errors=" +
      summary.errors.to_string() +
      " budget=" +
      gate.max_errors.to_string(),
    ),
  )
  reasons.push(
    gate_reason(
      "warnings",
      summary.warnings <= gate.max_warnings,
      "warnings=" +
      summary.warnings.to_string() +
      " budget=" +
      gate.max_warnings.to_string(),
    ),
  )
  reasons.push(
    gate_reason(
      "violations",
      summary.total <= gate.max_violations,
      "violations=" +
      summary.total.to_string() +
      " budget=" +
      gate.max_violations.to_string(),
    ),
  )
  gate_decision(gate, reasons, diagnostics)
}

///|
pub fn QualityGate::check_events(
  gate : QualityGate,
  events : Array[Event],
  policy : EvaluationPolicy,
) -> GateDecision {
  gate.check_diagnostics(diagnose_with_policy(events, policy))
}

///|
pub fn QualityGate::check_scenarios(
  gate : QualityGate,
  results : Array[ScenarioResult],
) -> GateDecision {
  let all_diagnostics : Array[Diagnostic] = []
  for result in results {
    for diagnostic in result.violations.map(diagnostic_from_violation) {
      all_diagnostics.push(diagnostic)
    }
  }
  let reasons : Array[GateReason] = []
  let summary = summarize_scenarios(results)
  reasons.push(
    gate_reason(
      "required-scenarios",
      required_names_present(results, gate.required_scenarios),
      "required=" + gate.required_scenarios.length().to_string(),
    ),
  )
  let passed = if gate.require_successful_scenarios {
    all_required_passed(results, gate.required_scenarios)
  } else {
    true
  }
  reasons.push(
    gate_reason(
      "scenario-status",
      passed,
      "failed=" + summary.failed_count.to_string(),
    ),
  )
  reasons.push(
    gate_reason(
      "violation-budget",
      summary.violation_count <= gate.max_violations,
      "violations=" +
      summary.violation_count.to_string() +
      " budget=" +
      gate.max_violations.to_string(),
    ),
  )
  gate_decision(gate, reasons, all_diagnostics)
}

///|
pub fn QualityGate::check_catalog(
  gate : QualityGate,
  catalog : ScenarioCatalog,
  max_retries : Int,
) -> GateDecision {
  let results = evaluate_catalog(catalog, max_retries)
  let scenario_results : Array[ScenarioResult] = []
  for result in results {
    scenario_results.push({
      name: result.name,
      passed: result.passed,
      violations: result.violations,
    })
  }
  gate.check_scenarios(scenario_results)
}

///|
pub fn QualityGate::check_suite(
  gate : QualityGate,
  results : Array[ScenarioResult],
) -> GateDecision {
  let reasons : Array[GateReason] = []
  let summary = summarize_scenarios(results)
  reasons.push(
    gate_reason(
      "required-scenarios",
      required_names_present(results, gate.required_scenarios),
      "required=" + gate.required_scenarios.length().to_string(),
    ),
  )
  reasons.push(
    gate_reason(
      "scenario-status",
      !gate.require_successful_scenarios || summary.failed_count == 0,
      "failed=" + summary.failed_count.to_string(),
    ),
  )
  reasons.push(
    gate_reason(
      "violation-budget",
      summary.violation_count <= gate.max_violations,
      "violations=" +
      summary.violation_count.to_string() +
      " budget=" +
      gate.max_violations.to_string(),
    ),
  )
  gate_decision(gate, reasons, [])
}

///|
pub fn gate_reasons_json(decision : GateDecision) -> String {
  Json::array(
    decision.reasons.map(reason => {
      Json::object({
        "code": Json(reason.code),
        "passed": Json(reason.passed),
        "message": Json(reason.message),
      })
    }),
  ).stringify()
}

///|
pub fn gate_decision_json(decision : GateDecision) -> String {
  Json::object({
    "gate": Json(decision.gate_name),
    "passed": Json(decision.passed),
    "score": Json(decision.score),
    "reasons": Json::array(
      decision.reasons.map(reason => {
        Json::object({
          "code": Json(reason.code),
          "passed": Json(reason.passed),
          "message": Json(reason.message),
        })
      }),
    ),
    "diagnostic_count": Json(decision.diagnostics.length()),
  }).stringify()
}

///|
pub fn gate_for_profile(profile : PolicyProfile) -> QualityGate {
  match profile {
    Permissive => QualityGate::for_regression().with_violation_budget(3)
    ReadOnly => QualityGate::for_library().with_violation_budget(0)
    Ticketing => QualityGate::for_regression().with_warning_budget(2)
    DataPipeline => QualityGate::for_regression().with_warning_budget(1)
    Strict => QualityGate::for_library().with_violation_budget(0)
  }
}

///|
pub fn gate_passes_events(
  events : Array[Event],
  profile : PolicyProfile,
) -> Bool {
  let gate = gate_for_profile(profile)
  gate.check_events(events, policy_for_profile(profile)).passed
}

///|
pub fn gate_passes_scenarios(results : Array[ScenarioResult]) -> Bool {
  QualityGate::for_regression().check_suite(results).passed
}
