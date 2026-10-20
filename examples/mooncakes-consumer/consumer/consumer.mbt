///|
pub fn smoke_violation_count() -> Int {
  let events = [
    @src.Event::new("call", "read_ticket", "call-1", Some("ticket-1"), None),
    @src.Event::new(
      "result",
      "read_ticket",
      "call-1",
      Some("ticket-1"),
      Some(true),
    ),
  ]
  @src.evaluate(events, 1).length()
}
