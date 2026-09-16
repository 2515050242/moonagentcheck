///|
test "diff distinguishes matching changed added and removed events" {
  let expected = [
    Event::new("call", "read", "c1", Some("op"), None),
    Event::new("result", "read", "c1", Some("op"), Some(true)),
  ]
  let actual = [
    Event::new("call", "read", "c1", Some("op"), None),
    Event::new("result", "write", "c1", Some("op"), Some(false)),
    Event::new("write-complete", "write", "c1", Some("op"), Some(true)),
  ]
  let diffs = diff_events(expected, actual)
  let summary = summarize_diff(diffs)
  assert_true(diffs.length() == 3)
  assert_true(matching_diffs(diffs).length() == 1)
  assert_true(changed_diffs(diffs).length() == 2)
  assert_true(summary.changed_positions == 1)
  assert_true(summary.added_positions == 1)
  assert_true(summary.removed_positions == 0)
  assert_true(summary.distance() == 2)
  assert_true(!summary.equal())
}

///|
test "diff reports field-level metadata changes" {
  let expected = [Event::new("call", "read", "c1", Some("op"), None)]
  let actual = [Event::new("call", "write", "c2", Some("other"), None)]
  let diff = diff_event_at(expected, actual, 0)
  assert_true(event_diff_kind_name(diff.kind) == "changed")
  assert_true(diff.field_names() == ["tool", "call_id", "operation_id"])
  assert_true(diff_has_rule_relevant_change([diff]))
  assert_true(first_changed_index([diff]) == Some(0))
}

///|
test "diff handles length changes and common prefixes" {
  let one = [Event::new("call", "read", "c1", None, None)]
  let two = [
    Event::new("call", "read", "c1", None, None),
    Event::new("result", "read", "c1", None, Some(true)),
  ]
  let diffs = diff_events(one, two)
  assert_true(added_diffs(diffs).length() == 1)
  assert_true(removed_diffs(diffs).length() == 0)
  assert_true(traces_share_prefix(one, two, 1))
  assert_true(!traces_share_prefix(one, two, 2))
  assert_true(trace_event_distance(one, two) == 1)
  assert_true(diff_tools(diffs) == ["read"])
  assert_true(diff_json(diffs).contains("added"))
  assert_true(diff_summary_json(summarize_diff(diffs)).contains("distance"))
}
