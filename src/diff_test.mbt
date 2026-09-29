///|
test "diff distinguishes matching changed added and removed events" {
  let expected = [
    @src.Event::new("call", "read", "c1", Some("op"), None),
    @src.Event::new("result", "read", "c1", Some("op"), Some(true)),
  ]
  let actual = [
    @src.Event::new("call", "read", "c1", Some("op"), None),
    @src.Event::new("result", "write", "c1", Some("op"), Some(false)),
    @src.Event::new("write-complete", "write", "c1", Some("op"), Some(true)),
  ]
  let diffs = @src.diff_events(expected, actual)
  let summary = @src.summarize_diff(diffs)
  assert_true(diffs.length() == 3)
  assert_true(@src.matching_diffs(diffs).length() == 1)
  assert_true(@src.changed_diffs(diffs).length() == 2)
  assert_true(summary.changed_positions == 1)
  assert_true(summary.added_positions == 1)
  assert_true(summary.removed_positions == 0)
  assert_true(summary.distance() == 2)
  assert_true(!summary.equal())
}

///|
test "diff reports field-level metadata changes" {
  let expected = [@src.Event::new("call", "read", "c1", Some("op"), None)]
  let actual = [@src.Event::new("call", "write", "c2", Some("other"), None)]
  let diff = @src.diff_event_at(expected, actual, 0)
  assert_true(@src.event_diff_kind_name(diff.kind) == "changed")
  assert_true(diff.field_names() == ["tool", "call_id", "operation_id"])
  assert_true(@src.diff_has_rule_relevant_change([diff]))
  assert_true(@src.first_changed_index([diff]) == Some(0))
}

///|
test "diff handles length changes and common prefixes" {
  let one = [@src.Event::new("call", "read", "c1", None, None)]
  let two = [
    @src.Event::new("call", "read", "c1", None, None),
    @src.Event::new("result", "read", "c1", None, Some(true)),
  ]
  let diffs = @src.diff_events(one, two)
  assert_true(@src.added_diffs(diffs).length() == 1)
  assert_true(@src.removed_diffs(diffs).length() == 0)
  assert_true(@src.traces_share_prefix(one, two, 1))
  assert_true(!@src.traces_share_prefix(one, two, 2))
  assert_true(@src.trace_event_distance(one, two) == 1)
  assert_true(@src.diff_tools(diffs) == ["read"])
  assert_true(@src.diff_json(diffs).contains("added"))
  assert_true(
    @src.diff_summary_json(@src.summarize_diff(diffs)).contains("distance"),
  )
}
