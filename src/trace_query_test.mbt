///|
test "trace query finds event families without changing order" {
  let events = [
    @src.Event::new("call", "read", "c1", Some("op"), None),
    @src.Event::new("result", "read", "c1", Some("op"), Some(true)),
    @src.Event::new("call", "write", "c2", Some("save"), None),
    @src.Event::new("write-complete", "write", "c2", Some("save"), Some(true)),
  ]
  let query = @src.TraceQuery::new(events)
  assert_true(query.len() == 4)
  assert_true(query.count_kind("call") == 2)
  assert_true(query.count_tool("read") == 2)
  assert_true(query.event_indices_for_kind("result") == [1])
  assert_true(query.call_ids() == ["c1", "c2"])
  assert_true(query.operation_ids() == ["op", "save"])
}

///|
test "trace query reports success and unresolved calls" {
  let query = @src.TraceQuery::new([
    @src.Event::new("call", "ok", "ok-call", Some("a"), None),
    @src.Event::new("result", "ok", "ok-call", Some("a"), Some(true)),
    @src.Event::new("call", "pending", "pending-call", Some("b"), None),
  ])
  assert_true(query.successful_call_ids() == ["ok-call"])
  assert_true(query.unresolved_call_ids() == ["pending-call"])
  assert_true(query.has_call("ok-call"))
  assert_true(query.has_result("ok-call"))
  assert_true(!query.has_result("pending-call"))
}

///|
test "trace query pairs the first result with each call" {
  let query = @src.TraceQuery::new([
    @src.Event::new("call", "ticket", "c1", Some("reply"), None),
    @src.Event::new("result", "ticket", "c1", Some("reply"), Some(false)),
    @src.Event::new("result", "ticket", "c1", Some("reply"), Some(true)),
  ])
  let pairs = @src.call_pairs(query)
  assert_true(pairs.length() == 1)
  assert_true(pairs[0].call_index == 0)
  assert_true(pairs[0].result_index == Some(1))
  assert_true(pairs[0].result == Some(query.events()[1]))
}

///|
test "trace windows clamp invalid ranges" {
  let query = @src.TraceQuery::new([
    @src.Event::new("call", "a", "a", None, None),
    @src.Event::new("result", "a", "a", None, Some(true)),
    @src.Event::new("write-complete", "a", "a", Some("save"), Some(true)),
  ])
  let window = @src.trace_window(query, -2, 20)
  assert_true(window.length() == 3)
  assert_true(window.contains_kind("write-complete"))
  assert_true(@src.trace_window(query, 2, 1).length() == 0)
}

///|
test "trace fingerprint and sequence checks are deterministic" {
  let events = [
    @src.Event::new("call", "read", "c1", Some("op"), None),
    @src.Event::new("result", "read", "c1", Some("op"), Some(true)),
  ]
  assert_true(
    @src.trace_fingerprint(events) ==
    "call:read:c1:op:unknown|result:read:c1:op:ok",
  )
  assert_true(@src.trace_contains_sequence(events, ["call", "result"]))
  assert_true(@src.trace_has_adjacent_kinds(events, "call", "result"))
  assert_true(@src.trace_events_equal(events, events))
  assert_true(@src.trace_first_difference(events, [events[0]]) == Some(1))
}
