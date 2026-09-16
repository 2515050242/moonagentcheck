///|
test "maps evaluated violations to stable codes" {
  let events = [Event::new("call", "load", "call-1", None, None)]
  let report = evaluate(events, 1)
  assert_true(violation_code(report[0]) == "AGC002")
}

///|
test "returns unknown for an unrecognized rule" {
  assert_true(rule_code("adapter-specific-rule") == "unknown")
}

///|
test "serializes scenario results in a stable JSON shape" {
  let results = evaluate_scenarios(
    [
      Scenario::new("read-ok", []),
      Scenario::new("orphan-result", [
        Event::new("result", "read", "call-2", Some("load"), Some(true)),
      ]),
    ],
    2,
  )
  let output = scenario_results_json(results)
  assert_true(
    output ==
    "[{\"name\":\"read-ok\",\"passed\":true,\"violations\":[]},{\"name\":\"orphan-result\",\"passed\":false,\"violations\":[{\"code\":\"AGC001\",\"rule\":\"orphan-result\",\"event_index\":0,\"message\":\"call-2\"}]}]",
  )
  assert_true(@json.valid(output))
}

///|
test "escapes report strings with standard JSON encoding" {
  let results = evaluate_scenarios(
    [
      Scenario::new("中文\"场景\\\n", [
        Event::new(
          "result",
          "read",
          "line\nquote\"slash\\tab\tcontrol\u{01}",
          Some("load"),
          Some(true),
        ),
      ]),
    ],
    2,
  )
  let output = scenario_results_json(results)
  assert_true(
    output ==
    "[{\"name\":\"中文\\\"场景\\\\\\n\",\"passed\":false,\"violations\":[{\"code\":\"AGC001\",\"rule\":\"orphan-result\",\"event_index\":0,\"message\":\"line\\nquote\\\"slash\\\\tab\\tcontrol\\u0001\"}]}]",
  )
  assert_true(@json.valid(output))
}
