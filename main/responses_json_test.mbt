///|
test "Responses JSON CLI reports a successful function call" {
  let report = @main.responses_json_report(
    "[{\"type\":\"function_call\",\"response_id\":\"resp-1\",\"operation_id\":\"ticket-1\",\"call_id\":\"call-1\",\"name\":\"read_ticket\"},{\"type\":\"function_call_output\",\"call_id\":\"call-1\",\"status\":\"completed\",\"outcome\":true}]",
  )
  assert_true(report.contains("\"passed\":true"))
  assert_true(@json.valid(report))
}

///|
test "Responses JSON CLI rejects completed output with unknown outcome" {
  let report = @main.responses_json_report(
    "[{\"type\":\"function_call\",\"response_id\":\"resp-unknown\",\"operation_id\":\"ticket-unknown\",\"call_id\":\"call-unknown\",\"name\":\"update_ticket\"},{\"type\":\"function_call_output\",\"call_id\":\"call-unknown\",\"status\":\"completed\"}]",
  )
  assert_true(report.contains("\"passed\":false"))
  assert_true(report.contains("\"code\":\"AGC018\""))
  assert_true(@json.valid(report))
}

///|
test "Responses JSON CLI rejects unsupported output items" {
  let report = @main.responses_json_report("[{\"type\":\"web_search_call\"}]")
  assert_true(report.contains("\"passed\":false"))
  assert_true(
    report.contains("unsupported Responses item type: web_search_call"),
  )
  assert_true(@json.valid(report))
}
