///|
/// A read-only query facade over an observed event stream.
///
/// Adapters should be able to inspect a trace without duplicating loops over
/// Array[Event]. The facade deliberately keeps the original order; ordering is
/// evidence and must not be hidden by a convenience API.
pub struct TraceQuery {
  events : Array[Event]
}

///|
pub fn TraceQuery::new(events : Array[Event]) -> TraceQuery {
  { events, }
}

///|
pub fn TraceQuery::from_trace(trace : Trace) -> TraceQuery {
  { events: trace.events(), }
}

///|
pub fn TraceQuery::len(query : TraceQuery) -> Int {
  query.events.length()
}

///|
pub fn TraceQuery::is_empty(query : TraceQuery) -> Bool {
  query.events.length() == 0
}

///|
pub fn TraceQuery::events(query : TraceQuery) -> Array[Event] {
  query.events
}

///|
pub fn TraceQuery::at(query : TraceQuery, index : Int) -> Event? {
  if index < 0 || index >= query.events.length() {
    None
  } else {
    Some(query.events[index])
  }
}

///|
pub fn TraceQuery::first(query : TraceQuery) -> Event? {
  query.at(0)
}

///|
pub fn TraceQuery::last(query : TraceQuery) -> Event? {
  query.at(query.events.length() - 1)
}

///|
pub fn TraceQuery::kind_at(query : TraceQuery, index : Int) -> String? {
  match query.at(index) {
    Some(event) => Some(event.kind)
    None => None
  }
}

///|
pub fn TraceQuery::event_indices_for_kind(
  query : TraceQuery,
  kind : String,
) -> Array[Int] {
  let indices : Array[Int] = []
  for index, event in query.events {
    if event.kind == kind {
      indices.push(index)
    }
  }
  indices
}

///|
pub fn TraceQuery::events_for_kind(
  query : TraceQuery,
  kind : String,
) -> Array[Event] {
  query.events.filter(event => event.kind == kind)
}

///|
pub fn TraceQuery::events_for_tool(
  query : TraceQuery,
  tool : String,
) -> Array[Event] {
  query.events.filter(event => event.tool == tool)
}

///|
pub fn TraceQuery::events_for_operation(
  query : TraceQuery,
  operation_id : String,
) -> Array[Event] {
  query.events.filter(event => event.operation_id == Some(operation_id))
}

///|
pub fn TraceQuery::events_for_call(
  query : TraceQuery,
  call_id : String,
) -> Array[Event] {
  query.events.filter(event => event.call_id == call_id)
}

///|
pub fn TraceQuery::count_kind(query : TraceQuery, kind : String) -> Int {
  query.events_for_kind(kind).length()
}

///|
pub fn TraceQuery::count_tool(query : TraceQuery, tool : String) -> Int {
  query.events_for_tool(tool).length()
}

///|
pub fn TraceQuery::has_kind(query : TraceQuery, kind : String) -> Bool {
  query.events.any(event => event.kind == kind)
}

///|
pub fn TraceQuery::has_tool(query : TraceQuery, tool : String) -> Bool {
  query.events.any(event => event.tool == tool)
}

///|
pub fn TraceQuery::has_call(query : TraceQuery, call_id : String) -> Bool {
  query.events.any(event => event.kind == "call" && event.call_id == call_id)
}

///|
pub fn TraceQuery::has_result(query : TraceQuery, call_id : String) -> Bool {
  query.events.any(event => event.kind == "result" && event.call_id == call_id)
}

///|
pub fn TraceQuery::call_ids(query : TraceQuery) -> Array[String] {
  let result : Array[String] = []
  for event in query.events {
    if event.kind == "call" && !result.contains(event.call_id) {
      result.push(event.call_id)
    }
  }
  result
}

///|
pub fn TraceQuery::operation_ids(query : TraceQuery) -> Array[String] {
  let result : Array[String] = []
  for event in query.events {
    match event.operation_id {
      Some(operation) if !result.contains(operation) => result.push(operation)
      _ => ()
    }
  }
  result
}

///|
pub fn TraceQuery::tool_names(query : TraceQuery) -> Array[String] {
  let result : Array[String] = []
  for event in query.events {
    if !result.contains(event.tool) {
      result.push(event.tool)
    }
  }
  result
}

///|
pub fn TraceQuery::successful_call_ids(query : TraceQuery) -> Array[String] {
  let result : Array[String] = []
  let calls : Map[String, Bool] = Map([])
  for event in query.events {
    if event.kind == "call" {
      calls[event.call_id] = false
    } else if event.kind == "result" {
      match event.ok {
        Some(true) => calls[event.call_id] = true
        _ => ()
      }
    }
  }
  for call_id in query.call_ids() {
    if calls.get(call_id) == Some(true) {
      result.push(call_id)
    }
  }
  result
}

///|
pub fn TraceQuery::unresolved_call_ids(query : TraceQuery) -> Array[String] {
  let result : Array[String] = []
  for call_id in query.call_ids() {
    if !query.has_result(call_id) {
      result.push(call_id)
    }
  }
  result
}

///|
pub struct CallPair {
  call : Event
  result : Event?
  call_index : Int
  result_index : Int?
}

///|
pub fn call_pairs(query : TraceQuery) -> Array[CallPair] {
  let pairs : Array[CallPair] = []
  for call_index, call in query.events {
    if call.kind == "call" {
      let mut result : Event? = None
      let mut result_index : Int? = None
      for index, candidate in query.events {
        if index > call_index &&
          candidate.kind == "result" &&
          candidate.call_id == call.call_id {
          match result {
            None => {
              result = Some(candidate)
              result_index = Some(index)
            }
            Some(_) => ()
          }
        }
      }
      pairs.push({ call, result, call_index, result_index, })
    }
  }
  pairs
}

///|
pub fn first_call(query : TraceQuery, call_id : String) -> Event? {
  for event in query.events {
    if event.kind == "call" && event.call_id == call_id {
      return Some(event)
    }
  }
  None
}

///|
pub fn first_result(query : TraceQuery, call_id : String) -> Event? {
  for event in query.events {
    if event.kind == "result" && event.call_id == call_id {
      return Some(event)
    }
  }
  None
}

///|
pub fn first_index_of(query : TraceQuery, call_id : String) -> Int? {
  for index, event in query.events {
    if event.call_id == call_id {
      return Some(index)
    }
  }
  None
}

///|
pub struct TraceWindow {
  start : Int
  end : Int
  events : Array[Event]
}

///|
pub fn trace_window(query : TraceQuery, start : Int, end : Int) -> TraceWindow {
  let safe_start = if start < 0 { 0 } else { start }
  let safe_end = if end > query.len() { query.len() } else { end }
  let events : Array[Event] = []
  if safe_start < safe_end {
    for index in safe_start..<safe_end {
      events.push(query.events[index])
    }
  }
  { start: safe_start, end: safe_end, events, }
}

///|
pub fn TraceWindow::length(window : TraceWindow) -> Int {
  window.events.length()
}

///|
pub fn TraceWindow::events(window : TraceWindow) -> Array[Event] {
  window.events
}

///|
pub fn TraceWindow::contains_kind(window : TraceWindow, kind : String) -> Bool {
  window.events.any(event => event.kind == kind)
}

///|
pub fn TraceWindow::query(window : TraceWindow) -> TraceQuery {
  TraceQuery::new(window.events)
}

///|
pub fn trace_fingerprint(events : Array[Event]) -> String {
  let parts : Array[String] = []
  for event in events {
    let operation = match event.operation_id {
      Some(value) => value
      None => "-"
    }
    let status = match event.ok {
      Some(true) => "ok"
      Some(false) => "failed"
      None => "unknown"
    }
    parts.push(
      event.kind +
      ":" +
      event.tool +
      ":" +
      event.call_id +
      ":" +
      operation +
      ":" +
      status,
    )
  }
  parts.join("|")
}

///|
pub fn trace_fingerprint_of(query : TraceQuery) -> String {
  trace_fingerprint(query.events)
}

///|
pub fn trace_contains_sequence(
  events : Array[Event],
  kinds : Array[String],
) -> Bool {
  if kinds.length() == 0 {
    return true
  }
  let mut cursor = 0
  for event in events {
    if event.kind == kinds[cursor] {
      cursor = cursor + 1
      if cursor == kinds.length() {
        return true
      }
    }
  }
  false
}

///|
pub fn trace_has_adjacent_kinds(
  events : Array[Event],
  left : String,
  right : String,
) -> Bool {
  if events.length() < 2 {
    return false
  }
  for index in 0..<(events.length() - 1) {
    if events[index].kind == left && events[index + 1].kind == right {
      return true
    }
  }
  false
}

///|
pub fn trace_event_distance(left : Array[Event], right : Array[Event]) -> Int {
  let distance = if left.length() > right.length() {
    left.length()
  } else {
    right.length()
  }
  let shared = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  let mut mismatches = 0
  for index in 0..<shared {
    if left[index] != right[index] {
      mismatches = mismatches + 1
    }
  }
  mismatches + distance - shared
}

///|
pub fn trace_events_equal(left : Array[Event], right : Array[Event]) -> Bool {
  trace_event_distance(left, right) == 0
}

///|
pub fn trace_first_difference(
  left : Array[Event],
  right : Array[Event],
) -> Int? {
  let shared = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  for index in 0..<shared {
    if left[index] != right[index] {
      return Some(index)
    }
  }
  if left.length() != right.length() {
    Some(shared)
  } else {
    None
  }
}
