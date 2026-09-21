///|
fn main {
  let trace = @src.Trace::new()
  trace.call("read_file", "read-1", Some("inspect-config"))
  trace.result("read_file", "read-1", Some("inspect-config"), Some(true))
  trace.call("write_file", "write-1", Some("update-config"))
  trace.result("write_file", "write-1", Some("update-config"), Some(true))
  trace.write_complete("write_file", "write-1", Some("update-config"))
  trace.write_complete("write_file", "write-1", Some("update-config"))

  let policy = @src.EvaluationPolicy::new(1, Some(["read_file", "write_file"]))
  let context = @src.PolicyContext::new("main/demo-policy", policy)
  let violations = @src.evaluate_with_context(trace.events(), context)
  if violations.length() != 1 || @src.violation_code(violations[0]) != "AGC004" {
    println("unexpected contract evaluation")
    abort("demo assertion failed")
  }

  let results = @src.evaluate_scenarios(
    [@src.Scenario::new("duplicate-write", trace.events())],
    1,
  )
  println("MoonAgentCheck runnable demo")
  println(@src.evaluation_report_json(trace.events(), context))
  println(@src.scenario_results_json(results))
  println(@src.trace_metrics_json(@src.collect_metrics(trace.events())))
}
