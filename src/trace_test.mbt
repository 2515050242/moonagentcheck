///|
test "trace builder creates a replayable call result write flow" {
  let trace = @src.Trace::new()
  trace.call("update_ticket", "call-1", Some("reply-42"))
  trace.result("update_ticket", "call-1", Some("reply-42"), Some(true))
  trace.write_complete("update_ticket", "call-1", Some("reply-42"))
  assert_true(trace.len() == 3)
  assert_true(!trace.is_empty())
  assert_true(@src.evaluate(trace.events(), 2).length() == 0)
}

///|
test "trace stats distinguish successful failed and unknown results" {
  let events = [
    @src.Event::new("call", "a", "a-1", None, None),
    @src.Event::new("result", "a", "a-1", None, Some(true)),
    @src.Event::new("result", "b", "b-1", None, Some(false)),
    @src.Event::new("result", "c", "c-1", None, None),
    @src.Event::new("write-complete", "a", "a-1", Some("a"), Some(true)),
  ]
  let stats = @src.trace_stats(events)
  assert_true(stats.event_count == 5)
  assert_true(stats.call_count == 1)
  assert_true(stats.result_count == 3)
  assert_true(stats.write_count == 1)
  assert_true(stats.successful_result_count == 1)
  assert_true(stats.failed_result_count == 1)
  assert_true(stats.unknown_result_count == 1)
}
