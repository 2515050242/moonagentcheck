///|
test "Responses function-call fields map to a complete core result" {
  let adaptation = adapt_responses_items([
    responses_function_call(
      "resp-42",
      Some("ticket-42"),
      "call-42",
      "update_ticket",
    ),
    responses_function_call_output("call-42", responses_completed(), Some(true)),
  ])
  assert_true(adaptation.issues.length() == 0)
  assert_true(adaptation.events.length() == 2)
  assert_true(
    adaptation.events[0] ==
    Event::new("call", "update_ticket", "call-42", Some("ticket-42"), None),
  )
  assert_true(
    adaptation.events[1] ==
    Event::new(
      "result",
      "update_ticket",
      "call-42",
      Some("ticket-42"),
      Some(true),
    ),
  )
  assert_true(evaluate(adaptation.events, 2).length() == 0)
}

///|
test "Responses output cannot invent a tool name without its call" {
  let adaptation = adapt_responses_items([
    responses_function_call_output(
      "call-missing",
      responses_completed(),
      Some(true),
    ),
  ])
  assert_true(adaptation.events.length() == 0)
  assert_true(adaptation.issues.length() == 1)
  assert_true(adaptation.issues[0].item_index == 0)
  assert_true(
    adaptation.issues[0].message ==
    "function call output has no preceding function call: call-missing",
  )
}

///|
test "Responses completed status alone remains an unknown result" {
  let adaptation = adapt_responses_items([
    responses_function_call(
      "resp-43",
      Some("ticket-43"),
      "call-43",
      "update_ticket",
    ),
    responses_function_call_output("call-43", responses_completed(), None),
  ])
  assert_true(adaptation.issues.length() == 0)
  assert_true(adaptation.events[1].ok == None)
  assert_true(evaluate(adaptation.events, 2).length() == 0)
}

///|
test "Responses in-progress output remains unknown despite an observed outcome" {
  assert_true(responses_output_ok(responses_in_progress(), Some(true)) == None)
}

///|
test "Responses incomplete output is a failed result" {
  let adaptation = adapt_responses_items([
    responses_function_call(
      "resp-44",
      Some("ticket-44"),
      "call-44",
      "update_ticket",
    ),
    responses_function_call_output(
      "call-44",
      responses_incomplete(),
      Some(true),
    ),
  ])
  assert_true(adaptation.events[1].ok == Some(false))
  let violations = evaluate(adaptation.events, 2)
  assert_true(violations.length() == 1)
  assert_true(violations[0].rule == "failed-result")
}

///|
test "Responses adapter rejects empty identity fields before producing events" {
  let adaptation = adapt_responses_items([
    responses_function_call("", Some("ticket-45"), "call-45", "update_ticket"),
    responses_function_call("resp-45", Some("ticket-45"), "", "update_ticket"),
    responses_function_call("resp-45", Some("ticket-45"), "call-45", ""),
  ])
  assert_true(adaptation.events.length() == 0)
  assert_true(adaptation.issues.length() == 3)
}

///|
test "Responses output retains the first call identity after duplicate telemetry" {
  let adaptation = adapt_responses_items([
    responses_function_call(
      "resp-47",
      Some("export-47"),
      "call-47",
      "write_file",
    ),
    responses_function_call(
      "resp-48",
      Some("notify-48"),
      "call-47",
      "send_email",
    ),
    responses_function_call_output("call-47", responses_completed(), Some(true)),
  ])
  assert_true(adaptation.issues.length() == 0)
  assert_true(
    adaptation.events[2] ==
    Event::new("result", "write_file", "call-47", Some("export-47"), Some(true)),
  )
  let violations = evaluate(adaptation.events, 2)
  assert_true(violations.length() == 1)
  assert_true(violations[0].rule == "duplicate-call-id")
  assert_true(violations[0].event_index == 1)
}

///|
test "Responses archive report retains mapping and policy evidence" {
  let context = PolicyContext::new(
    "ci/ticketing-policy",
    EvaluationPolicy::new(1, Some(["get_ticket"])),
  )
  let output = responses_evaluation_report_json(
    [
      responses_function_call(
        "resp-46",
        Some("ticket-46"),
        "call-46",
        "update_ticket",
      ),
      responses_function_call_output(
        "call-missing",
        responses_completed(),
        Some(true),
      ),
    ],
    context,
  )
  assert_true(
    output ==
    "{\"adapter\":\"openai-responses-function-call\",\"mapped_event_count\":1,\"mapping_issues\":[{\"item_index\":1,\"message\":\"function call output has no preceding function call: call-missing\"}],\"policy_source\":\"ci/ticketing-policy\",\"policy\":{\"max_retries\":1,\"tool_allowlist\":[\"get_ticket\"],\"restricted\":true,\"valid\":true},\"passed\":false,\"violations\":[{\"code\":\"AGC012\",\"rule\":\"tool-not-allowed\",\"event_index\":0,\"message\":\"update_ticket\"},{\"code\":\"AGC002\",\"rule\":\"missing-result\",\"event_index\":0,\"message\":\"call-46\"}]}",
  )
  assert_true(@json.valid(output))
}

///|
test "Responses archive report JSON-escapes mapping issue evidence" {
  let output = responses_evaluation_report_json(
    [
      responses_function_call_output(
        "call\nquote\"slash\\",
        responses_completed(),
        Some(true),
      ),
    ],
    PolicyContext::new("ci/fixture", EvaluationPolicy::new(1, None)),
  )
  assert_true(
    output ==
    "{\"adapter\":\"openai-responses-function-call\",\"mapped_event_count\":0,\"mapping_issues\":[{\"item_index\":0,\"message\":\"function call output has no preceding function call: call\\nquote\\\"slash\\\\\"}],\"policy_source\":\"ci/fixture\",\"policy\":{\"max_retries\":1,\"tool_allowlist\":null,\"restricted\":false,\"valid\":true},\"passed\":false,\"violations\":[]}",
  )
  assert_true(@json.valid(output))
}
