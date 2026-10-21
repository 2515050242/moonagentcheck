///|
fn report_with_outcome(outcome : Bool?) -> String {
  @src.responses_evaluation_report_json(
    [
      @src.responses_function_call(
        "resp-consumer",
        Some("ticket-consumer"),
        "call-consumer",
        "read_ticket",
      ),
      @src.responses_function_call_output(
        "call-consumer",
        @src.responses_completed(),
        outcome,
      ),
    ],
    @src.PolicyContext::new(
      "consumer/registry-package",
      @src.EvaluationPolicy::new(1, None),
    ),
  )
}

///|
pub fn success_report() -> String {
  report_with_outcome(Some(true))
}

///|
pub fn unknown_report() -> String {
  report_with_outcome(None)
}
