///|
test "Responses function-call fields map to a complete core result" {
  let adaptation = @src.adapt_responses_items([
    @src.responses_function_call(
      "resp-42",
      Some("ticket-42"),
      "call-42",
      "update_ticket",
    ),
    @src.responses_function_call_output(
      "call-42",
      @src.responses_completed(),
      Some(true),
    ),
  ])
  assert_true(adaptation.issues.length() == 0)
  assert_true(adaptation.events.length() == 2)
  assert_true(
    adaptation.events[0] ==
    @src.Event::new("call", "update_ticket", "call-42", Some("ticket-42"), None),
  )
  assert_true(
    adaptation.events[1] ==
    @src.Event::new(
      "result",
      "update_ticket",
      "call-42",
      Some("ticket-42"),
      Some(true),
    ),
  )
  assert_true(@src.evaluate(adaptation.events, 2).length() == 0)
}

///|
test "Responses message and reasoning items do not disturb tool pairing" {
  let adaptation = @src.adapt_responses_items([
    @src.responses_non_tool_item("message"),
    @src.responses_function_call(
      "resp-mixed",
      Some("operation-mixed"),
      "call-mixed",
      "read_record",
    ),
    @src.responses_non_tool_item("reasoning"),
    @src.responses_function_call_output(
      "call-mixed",
      @src.responses_completed(),
      Some(true),
    ),
    @src.responses_non_tool_item("message"),
  ])
  assert_true(adaptation.issues.length() == 0)
  assert_true(adaptation.events.length() == 2)
  assert_true(adaptation.events[0].kind == "call")
  assert_true(adaptation.events[1].kind == "result")
  assert_true(adaptation.events[1].call_id == "call-mixed")
  assert_true(adaptation.events[1].operation_id == Some("operation-mixed"))
  assert_true(@src.evaluate(adaptation.events, 1).length() == 0)
}

///|
test "Responses adapter reports unsupported items at their source position" {
  let adaptation = @src.adapt_responses_items([
    @src.responses_non_tool_item("message"),
    @src.responses_function_call(
      "resp-supported",
      None,
      "call-supported",
      "read_record",
    ),
    @src.responses_non_tool_item("web_search_call"),
  ])
  assert_true(adaptation.events.length() == 1)
  assert_true(adaptation.issues.length() == 1)
  assert_true(adaptation.issues[0].item_index == 2)
  assert_true(
    adaptation.issues[0].message ==
    "unsupported Responses item type: web_search_call",
  )
}

///|
test "Responses output cannot invent a tool name without its call" {
  let adaptation = @src.adapt_responses_items([
    @src.responses_function_call_output(
      "call-missing",
      @src.responses_completed(),
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
  let adaptation = @src.adapt_responses_items([
    @src.responses_function_call(
      "resp-43",
      Some("ticket-43"),
      "call-43",
      "update_ticket",
    ),
    @src.responses_function_call_output(
      "call-43",
      @src.responses_completed(),
      None,
    ),
  ])
  assert_true(adaptation.issues.length() == 0)
  assert_true(adaptation.events[1].ok == None)
  assert_true(@src.evaluate(adaptation.events, 2).length() == 0)
}

///|
test "Responses in-progress output remains unknown despite an observed outcome" {
  assert_true(
    @src.responses_output_ok(@src.responses_in_progress(), Some(true)) == None,
  )
}

///|
test "Responses incomplete output is a failed result" {
  let adaptation = @src.adapt_responses_items([
    @src.responses_function_call(
      "resp-44",
      Some("ticket-44"),
      "call-44",
      "update_ticket",
    ),
    @src.responses_function_call_output(
      "call-44",
      @src.responses_incomplete(),
      Some(true),
    ),
  ])
  assert_true(adaptation.events[1].ok == Some(false))
  let violations = @src.evaluate(adaptation.events, 2)
  assert_true(violations.length() == 1)
  assert_true(violations[0].rule == "failed-result")
}

///|
test "Responses adapter rejects empty identity fields before producing events" {
  let adaptation = @src.adapt_responses_items([
    @src.responses_function_call(
      "",
      Some("ticket-45"),
      "call-45",
      "update_ticket",
    ),
    @src.responses_function_call(
      "resp-45",
      Some("ticket-45"),
      "",
      "update_ticket",
    ),
    @src.responses_function_call("resp-45", Some("ticket-45"), "call-45", ""),
  ])
  assert_true(adaptation.events.length() == 0)
  assert_true(adaptation.issues.length() == 3)
}

///|
test "Responses output retains the first call identity after duplicate telemetry" {
  let adaptation = @src.adapt_responses_items([
    @src.responses_function_call(
      "resp-47",
      Some("export-47"),
      "call-47",
      "write_file",
    ),
    @src.responses_function_call(
      "resp-48",
      Some("notify-48"),
      "call-47",
      "send_email",
    ),
    @src.responses_function_call_output(
      "call-47",
      @src.responses_completed(),
      Some(true),
    ),
  ])
  assert_true(adaptation.issues.length() == 0)
  assert_true(
    adaptation.events[2] ==
    @src.Event::new(
      "result",
      "write_file",
      "call-47",
      Some("export-47"),
      Some(true),
    ),
  )
  let violations = @src.evaluate(adaptation.events, 2)
  assert_true(violations.length() == 1)
  assert_true(violations[0].rule == "duplicate-call-id")
  assert_true(violations[0].event_index == 1)
}

///|
test "Responses archive report retains mapping and policy evidence" {
  let context = @src.PolicyContext::new(
    "ci/ticketing-policy",
    @src.EvaluationPolicy::new(1, Some(["get_ticket"])),
  )
  let output = @src.responses_evaluation_report_json(
    [
      @src.responses_function_call(
        "resp-46",
        Some("ticket-46"),
        "call-46",
        "update_ticket",
      ),
      @src.responses_function_call_output(
        "call-missing",
        @src.responses_completed(),
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
  let output = @src.responses_evaluation_report_json(
    [
      @src.responses_function_call_output(
        "call\nquote\"slash\\",
        @src.responses_completed(),
        Some(true),
      ),
    ],
    @src.PolicyContext::new("ci/fixture", @src.EvaluationPolicy::new(1, None)),
  )
  assert_true(
    output ==
    "{\"adapter\":\"openai-responses-function-call\",\"mapped_event_count\":0,\"mapping_issues\":[{\"item_index\":0,\"message\":\"function call output has no preceding function call: call\\nquote\\\"slash\\\\\"}],\"policy_source\":\"ci/fixture\",\"policy\":{\"max_retries\":1,\"tool_allowlist\":null,\"restricted\":false,\"valid\":true},\"passed\":false,\"violations\":[]}",
  )
  assert_true(@json.valid(output))
}
