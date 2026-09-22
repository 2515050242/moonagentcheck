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
