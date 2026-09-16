///|
/// A small event-stream container for adapters and replay fixtures.
pub struct Trace {
  events : Array[Event]
}

///|
pub fn Trace::new() -> Trace {
  { events: [], }
}

///|
pub fn Trace::from_events(events : Array[Event]) -> Trace {
  { events, }
}

///|
pub fn Trace::push(trace : Trace, event : Event) -> Unit {
  trace.events.push(event)
}

///|
pub fn Trace::call(
  trace : Trace,
  tool : String,
  call_id : String,
  operation_id : String?,
) -> Unit {
  trace.push(Event::new("call", tool, call_id, operation_id, None))
}

///|
pub fn Trace::result(
  trace : Trace,
  tool : String,
  call_id : String,
  operation_id : String?,
  ok : Bool?,
) -> Unit {
  trace.push(Event::new("result", tool, call_id, operation_id, ok))
}

///|
pub fn Trace::write_complete(
  trace : Trace,
  tool : String,
  call_id : String,
  operation_id : String?,
) -> Unit {
  trace.push(
    Event::new("write-complete", tool, call_id, operation_id, Some(true)),
  )
}

///|
pub fn Trace::len(trace : Trace) -> Int {
  trace.events.length()
}

///|
pub fn Trace::is_empty(trace : Trace) -> Bool {
  trace.events.length() == 0
}

///|
pub fn Trace::events(trace : Trace) -> Array[Event] {
  trace.events
}

///|
pub struct TraceStats {
  event_count : Int
  call_count : Int
  result_count : Int
  write_count : Int
  successful_result_count : Int
  failed_result_count : Int
  unknown_result_count : Int
}

///|
pub fn trace_stats(events : Array[Event]) -> TraceStats {
  let mut call_count = 0
  let mut result_count = 0
  let mut write_count = 0
  let mut successful_result_count = 0
  let mut failed_result_count = 0
  let mut unknown_result_count = 0
  for event in events {
    if event.kind == "call" {
      call_count = call_count + 1
    } else if event.kind == "result" {
      result_count = result_count + 1
      match event.ok {
        Some(true) => successful_result_count = successful_result_count + 1
        Some(false) => failed_result_count = failed_result_count + 1
        None => unknown_result_count = unknown_result_count + 1
      }
    } else if event.kind == "write-complete" {
      write_count = write_count + 1
    }
  }
  {
    event_count: events.length(),
    call_count,
    result_count,
    write_count,
    successful_result_count,
    failed_result_count,
    unknown_result_count,
  }
}
