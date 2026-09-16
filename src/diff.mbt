///|
/// Classification used when comparing an expected trace with an observed one.
pub enum EventDiffKind {
  Match
  Added
  Removed
  Changed
} derive(Eq, Debug)

///|
pub fn event_diff_kind_name(kind : EventDiffKind) -> String {
  match kind {
    Match => "match"
    Added => "added"
    Removed => "removed"
    Changed => "changed"
  }
}

///|
pub enum EventField {
  KindField
  ToolField
  CallIdField
  OperationIdField
  StatusField
} derive(Eq, Debug)

///|
pub fn event_field_name(field : EventField) -> String {
  match field {
    KindField => "kind"
    ToolField => "tool"
    CallIdField => "call_id"
    OperationIdField => "operation_id"
    StatusField => "ok"
  }
}

///|
pub struct EventDiff {
  index : Int
  kind : EventDiffKind
  expected : Event?
  actual : Event?
  changed_fields : Array[EventField]
}

///|
pub fn EventDiff::is_match(diff : EventDiff) -> Bool {
  diff.kind == Match
}

///|
pub fn EventDiff::is_change(diff : EventDiff) -> Bool {
  diff.kind == Changed
}

///|
pub fn EventDiff::is_length_change(diff : EventDiff) -> Bool {
  diff.kind == Added || diff.kind == Removed
}

///|
pub fn EventDiff::field_names(diff : EventDiff) -> Array[String] {
  diff.changed_fields.map(event_field_name)
}

///|
pub fn EventDiff::render(diff : EventDiff) -> String {
  let fields = diff.field_names().join(",")
  let suffix = if fields == "" { "" } else { " fields=" + fields }
  "index=" +
  diff.index.to_string() +
  " kind=" +
  event_diff_kind_name(diff.kind) +
  suffix
}

///|
fn optional_string_changed(left : String?, right : String?) -> Bool {
  left != right
}

///|
fn event_changed_fields(expected : Event, actual : Event) -> Array[EventField] {
  let fields : Array[EventField] = []
  if expected.kind != actual.kind {
    fields.push(KindField)
  }
  if expected.tool != actual.tool {
    fields.push(ToolField)
  }
  if expected.call_id != actual.call_id {
    fields.push(CallIdField)
  }
  if optional_string_changed(expected.operation_id, actual.operation_id) {
    fields.push(OperationIdField)
  }
  if expected.ok != actual.ok {
    fields.push(StatusField)
  }
  fields
}

///|
pub fn diff_event_at(
  expected : Array[Event],
  actual : Array[Event],
  index : Int,
) -> EventDiff {
  let has_expected = index >= 0 && index < expected.length()
  let has_actual = index >= 0 && index < actual.length()
  match (has_expected, has_actual) {
    (false, false) =>
      { index, kind: Match, expected: None, actual: None, changed_fields: [], }
    (false, true) =>
      {
        index,
        kind: Added,
        expected: None,
        actual: Some(actual[index]),
        changed_fields: [],
      }
    (true, false) =>
      {
        index,
        kind: Removed,
        expected: Some(expected[index]),
        actual: None,
        changed_fields: [],
      }
    (true, true) => {
      let fields = event_changed_fields(expected[index], actual[index])
      {
        index,
        kind: if fields.length() == 0 {
          Match
        } else {
          Changed
        },
        expected: Some(expected[index]),
        actual: Some(actual[index]),
        changed_fields: fields,
      }
    }
  }
}

///|
pub fn diff_events(
  expected : Array[Event],
  actual : Array[Event],
) -> Array[EventDiff] {
  let diffs : Array[EventDiff] = []
  let length = if expected.length() > actual.length() {
    expected.length()
  } else {
    actual.length()
  }
  for index in 0..<length {
    diffs.push(diff_event_at(expected, actual, index))
  }
  diffs
}

///|
pub fn changed_diffs(diffs : Array[EventDiff]) -> Array[EventDiff] {
  diffs.filter(diff => diff.kind != Match)
}

///|
pub fn matching_diffs(diffs : Array[EventDiff]) -> Array[EventDiff] {
  diffs.filter(diff => diff.kind == Match)
}

///|
pub fn added_diffs(diffs : Array[EventDiff]) -> Array[EventDiff] {
  diffs.filter(diff => diff.kind == Added)
}

///|
pub fn removed_diffs(diffs : Array[EventDiff]) -> Array[EventDiff] {
  diffs.filter(diff => diff.kind == Removed)
}

///|
pub fn field_change_count(diffs : Array[EventDiff], field : EventField) -> Int {
  let mut count = 0
  for diff in diffs {
    if diff.changed_fields.contains(field) {
      count = count + 1
    }
  }
  count
}

///|
pub struct DiffSummary {
  total_positions : Int
  matched_positions : Int
  changed_positions : Int
  added_positions : Int
  removed_positions : Int
  changed_fields : Int
}

///|
pub fn summarize_diff(diffs : Array[EventDiff]) -> DiffSummary {
  let mut matched = 0
  let mut changed = 0
  let mut added = 0
  let mut removed = 0
  let mut fields = 0
  for diff in diffs {
    fields = fields + diff.changed_fields.length()
    match diff.kind {
      Match => matched = matched + 1
      Changed => changed = changed + 1
      Added => added = added + 1
      Removed => removed = removed + 1
    }
  }
  {
    total_positions: diffs.length(),
    matched_positions: matched,
    changed_positions: changed,
    added_positions: added,
    removed_positions: removed,
    changed_fields: fields,
  }
}

///|
pub fn DiffSummary::equal(summary : DiffSummary) -> Bool {
  summary.changed_positions == 0 &&
  summary.added_positions == 0 &&
  summary.removed_positions == 0
}

///|
pub fn DiffSummary::distance(summary : DiffSummary) -> Int {
  summary.changed_positions +
  summary.added_positions +
  summary.removed_positions
}

///|
pub fn DiffSummary::render(summary : DiffSummary) -> String {
  "total=" +
  summary.total_positions.to_string() +
  " matched=" +
  summary.matched_positions.to_string() +
  " changed=" +
  summary.changed_positions.to_string() +
  " added=" +
  summary.added_positions.to_string() +
  " removed=" +
  summary.removed_positions.to_string() +
  " fields=" +
  summary.changed_fields.to_string()
}

///|
pub fn diff_json(diffs : Array[EventDiff]) -> String {
  Json::array(
    diffs.map(diff => {
      Json::object({
        "index": Json(diff.index),
        "kind": Json(event_diff_kind_name(diff.kind)),
        "fields": Json::array(diff.field_names().map(field => Json(field))),
      })
    }),
  ).stringify()
}

///|
pub fn diff_summary_json(summary : DiffSummary) -> String {
  Json::object({
    "total_positions": Json(summary.total_positions),
    "matched_positions": Json(summary.matched_positions),
    "changed_positions": Json(summary.changed_positions),
    "added_positions": Json(summary.added_positions),
    "removed_positions": Json(summary.removed_positions),
    "changed_fields": Json(summary.changed_fields),
    "equal": Json(summary.equal()),
    "distance": Json(summary.distance()),
  }).stringify()
}

///|
pub fn first_changed_diff(diffs : Array[EventDiff]) -> EventDiff? {
  for diff in diffs {
    if diff.kind != Match {
      return Some(diff)
    }
  }
  None
}

///|
pub fn first_changed_index(diffs : Array[EventDiff]) -> Int? {
  match first_changed_diff(diffs) {
    Some(diff) => Some(diff.index)
    None => None
  }
}

///|
pub fn traces_share_prefix(
  expected : Array[Event],
  actual : Array[Event],
  length : Int,
) -> Bool {
  if length < 0 || length > expected.length() || length > actual.length() {
    false
  } else {
    let diffs = diff_events(expected, actual)
    for diff in diffs {
      if diff.index < length && diff.kind != Match {
        return false
      }
    }
    true
  }
}

///|
pub fn diff_tools(diffs : Array[EventDiff]) -> Array[String] {
  let tools : Array[String] = []
  for diff in diffs {
    match diff.actual {
      Some(event) if !tools.contains(event.tool) => tools.push(event.tool)
      _ => ()
    }
    match diff.expected {
      Some(event) if !tools.contains(event.tool) => tools.push(event.tool)
      _ => ()
    }
  }
  tools
}

///|
pub fn diff_has_field(diffs : Array[EventDiff], field : EventField) -> Bool {
  diffs.any(diff => diff.changed_fields.contains(field))
}

///|
pub fn diff_has_rule_relevant_change(diffs : Array[EventDiff]) -> Bool {
  diff_has_field(diffs, CallIdField) ||
  diff_has_field(diffs, OperationIdField) ||
  diff_has_field(diffs, StatusField)
}

///|
pub fn diff_report(expected : Array[Event], actual : Array[Event]) -> String {
  let diffs = diff_events(expected, actual)
  let summary = summarize_diff(diffs)
  summary.render() + "\n" + diffs.map(diff => diff.render()).join("\n")
}
