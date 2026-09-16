///|
test "trace builder creates a replayable call result write flow" {
  let trace = Trace::new()
  trace.call("update_ticket", "call-1", Some("reply-42"))
  trace.result("update_ticket", "call-1", Some("reply-42"), Some(true))
  trace.write_complete("update_ticket", "call-1", Some("reply-42"))
  assert_true(trace.len() == 3)
  assert_true(!trace.is_empty())
  assert_true(evaluate(trace.events(), 2).length() == 0)
}

///|
test "trace stats distinguish successful failed and unknown results" {
  let events = [
    Event::new("call", "a", "a-1", None, None),
    Event::new("result", "a", "a-1", None, Some(true)),
    Event::new("result", "b", "b-1", None, Some(false)),
    Event::new("result", "c", "c-1", None, None),
    Event::new("write-complete", "a", "a-1", Some("a"), Some(true)),
  ]
  let stats = trace_stats(events)
  assert_true(stats.event_count == 5)
  assert_true(stats.call_count == 1)
  assert_true(stats.result_count == 3)
  assert_true(stats.write_count == 1)
  assert_true(stats.successful_result_count == 1)
  assert_true(stats.failed_result_count == 1)
  assert_true(stats.unknown_result_count == 1)
}
