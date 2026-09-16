///|
/// Cursor status for deterministic trace replay.
pub enum ReplayStatus {
  BeforeStart
  Running
  Finished
  Halted
} derive(Eq, Debug)

///|
pub fn replay_status_name(status : ReplayStatus) -> String {
  match status {
    BeforeStart => "before-start"
    Running => "running"
    Finished => "finished"
    Halted => "halted"
  }
}

///|
/// A replay cursor makes it possible for a UI, test runner, or adapter to
/// inspect one event at a time while keeping the original trace immutable.
pub struct Replay {
  events : Array[Event]
  cursor_state : Array[Int]
  halted_state : Array[Bool]
  halted_reason_state : Array[String?]
}

///|
pub fn Replay::new(events : Array[Event]) -> Replay {
  {
    events,
    cursor_state: [0],
    halted_state: [false],
    halted_reason_state: [None],
  }
}

///|
pub fn Replay::from_trace(trace : Trace) -> Replay {
  Replay::new(trace.events())
}

///|
pub fn Replay::len(replay : Replay) -> Int {
  replay.events.length()
}

///|
pub fn Replay::position(replay : Replay) -> Int {
  replay.cursor_state[0]
}

///|
pub fn Replay::status(replay : Replay) -> ReplayStatus {
  if replay.halted_state[0] {
    Halted
  } else if replay.position() >= replay.events.length() {
    Finished
  } else if replay.position() == 0 {
    BeforeStart
  } else {
    Running
  }
}

///|
pub fn Replay::status_name(replay : Replay) -> String {
  replay_status_name(replay.status())
}

///|
pub fn Replay::done(replay : Replay) -> Bool {
  replay.position() >= replay.events.length() || replay.status() == Halted
}

///|
pub fn Replay::remaining(replay : Replay) -> Int {
  let remaining = replay.events.length() - replay.position()
  if remaining < 0 {
    0
  } else {
    remaining
  }
}

///|
pub fn Replay::progress(replay : Replay) -> Int {
  if replay.events.length() == 0 {
    100
  } else {
    replay.position() * 100 / replay.events.length()
  }
}

///|
pub fn Replay::events(replay : Replay) -> Array[Event] {
  replay.events
}

///|
pub fn Replay::current(replay : Replay) -> Event? {
  if replay.position() == 0 || replay.position() > replay.events.length() {
    None
  } else {
    Some(replay.events[replay.position() - 1])
  }
}

///|
pub fn Replay::peek(replay : Replay) -> Event? {
  if replay.done() {
    None
  } else {
    Some(replay.events[replay.position()])
  }
}

///|
pub struct ReplayObservation {
  index : Int
  event : Event
  remaining : Int
  status : ReplayStatus
}

///|
pub fn Replay::next(replay : Replay) -> ReplayObservation? {
  if replay.done() {
    None
  } else {
    let index = replay.position()
    let event = replay.events[index]
    replay.cursor_state[0] = replay.position() + 1
    Some({
      index,
      event,
      remaining: replay.remaining(),
      status: replay.status(),
    })
  }
}

///|
pub fn ReplayObservation::is_last(observation : ReplayObservation) -> Bool {
  observation.remaining == 0
}

///|
pub fn ReplayObservation::kind(observation : ReplayObservation) -> String {
  observation.event.kind
}

///|
pub fn ReplayObservation::call_id(observation : ReplayObservation) -> String {
  observation.event.call_id
}

///|
pub fn Replay::reset(replay : Replay) -> Unit {
  replay.cursor_state[0] = 0
  replay.halted_state[0] = false
  replay.halted_reason_state[0] = None
}

///|
pub fn Replay::seek(replay : Replay, position : Int) -> Bool {
  if position < 0 || position > replay.events.length() {
    false
  } else {
    replay.cursor_state[0] = position
    replay.halted_state[0] = false
    replay.halted_reason_state[0] = None
    true
  }
}

///|
pub fn Replay::skip(replay : Replay, count : Int) -> Int {
  let safe_count = if count < 0 { 0 } else { count }
  let target = replay.position() + safe_count
  let final_position = if target > replay.events.length() {
    replay.events.length()
  } else {
    target
  }
  let _ = replay.seek(final_position)
  final_position
}

///|
pub fn Replay::halt(replay : Replay, reason : String) -> Unit {
  replay.halted_state[0] = true
  replay.halted_reason_state[0] = Some(reason)
}

///|
pub fn Replay::halted_reason(replay : Replay) -> String? {
  replay.halted_reason_state[0]
}

///|
pub fn replay_all(replay : Replay) -> Array[ReplayObservation] {
  let observations : Array[ReplayObservation] = []
  while !replay.done() {
    match replay.next() {
      Some(observation) => observations.push(observation)
      None => break
    }
  }
  observations
}

///|
pub fn replay_until_kind(replay : Replay, kind : String) -> ReplayObservation? {
  while !replay.done() {
    match replay.next() {
      Some(observation) =>
        if observation.event.kind == kind {
          return Some(observation)
        }
      None => return None
    }
  }
  None
}

///|
pub fn replay_until_call(
  replay : Replay,
  call_id : String,
) -> ReplayObservation? {
  while !replay.done() {
    match replay.next() {
      Some(observation) =>
        if observation.event.call_id == call_id {
          return Some(observation)
        }
      None => return None
    }
  }
  None
}

///|
pub struct ReplayCheckpoint {
  position : Int
  status : ReplayStatus
  halted_reason : String?
}

///|
pub fn Replay::checkpoint(replay : Replay) -> ReplayCheckpoint {
  {
    position: replay.position(),
    status: replay.status(),
    halted_reason: replay.halted_reason(),
  }
}

///|
pub fn Replay::restore(replay : Replay, checkpoint : ReplayCheckpoint) -> Bool {
  if checkpoint.position < 0 || checkpoint.position > replay.events.length() {
    false
  } else {
    replay.cursor_state[0] = checkpoint.position
    replay.halted_state[0] = checkpoint.status == Halted
    replay.halted_reason_state[0] = checkpoint.halted_reason
    true
  }
}

///|
pub fn replay_prefix(replay : Replay) -> Array[Event] {
  let prefix : Array[Event] = []
  for index in 0..<replay.position() {
    prefix.push(replay.events[index])
  }
  prefix
}

///|
pub fn replay_validate(replay : Replay, max_retries : Int) -> Array[Violation] {
  evaluate(replay_prefix(replay), max_retries)
}

///|
pub struct ReplayStats {
  total : Int
  consumed : Int
  remaining : Int
  call_events : Int
  result_events : Int
  write_events : Int
  progress : Int
  status : ReplayStatus
}

///|
pub fn replay_stats(replay : Replay) -> ReplayStats {
  let stats = trace_stats(replay.events)
  {
    total: replay.len(),
    consumed: replay.position(),
    remaining: replay.remaining(),
    call_events: stats.call_count,
    result_events: stats.result_count,
    write_events: stats.write_count,
    progress: replay.progress(),
    status: replay.status(),
  }
}

///|
pub fn ReplayStats::render(stats : ReplayStats) -> String {
  "consumed=" +
  stats.consumed.to_string() +
  "/" +
  stats.total.to_string() +
  " remaining=" +
  stats.remaining.to_string() +
  " progress=" +
  stats.progress.to_string() +
  "% status=" +
  replay_status_name(stats.status)
}

///|
pub fn replay_digest(replay : Replay) -> String {
  trace_fingerprint(replay_prefix(replay))
}

///|
pub fn replay_positions_for_kind(replay : Replay, kind : String) -> Array[Int] {
  TraceQuery::new(replay.events).event_indices_for_kind(kind)
}

///|
pub fn replay_is_at_end(replay : Replay) -> Bool {
  replay.position() == replay.len()
}

///|
pub fn replay_can_step(replay : Replay) -> Bool {
  !replay.done()
}

///|
pub fn replay_status_json(replay : Replay) -> String {
  let stats = replay_stats(replay)
  Json::object({
    "total": Json(stats.total),
    "consumed": Json(stats.consumed),
    "remaining": Json(stats.remaining),
    "progress": Json(stats.progress),
    "status": Json(replay_status_name(stats.status)),
    "digest": Json(replay_digest(replay)),
  }).stringify()
}
