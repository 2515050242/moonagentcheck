///|
test "replay advances one observation at a time" {
  let replay = @src.Replay::new([
    @src.Event::new("call", "read", "c1", None, None),
    @src.Event::new("result", "read", "c1", None, Some(true)),
  ])
  assert_true(replay.status_name() == "before-start")
  assert_true(replay.progress() == 0)
  assert_true(replay.peek() != None)
  let first = replay.next()
  match first {
    Some(_) => ()
    None => assert_true(false)
  }
  assert_true(replay.position() == 1)
  assert_true(replay.status_name() == "running")
  assert_true(first.unwrap().kind() == "call")
  let second = replay.next()
  assert_true(second.unwrap().is_last())
  assert_true(replay.done())
  assert_true(replay.status_name() == "finished")
  match replay.next() {
    Some(_) => assert_true(false)
    None => ()
  }
}

///|
test "replay checkpoints restore a debugging position" {
  let replay = @src.Replay::new([
    @src.Event::new("call", "a", "a", None, None),
    @src.Event::new("result", "a", "a", None, Some(true)),
    @src.Event::new("write-complete", "a", "a", Some("save"), Some(true)),
  ])
  let _ = replay.next()
  let checkpoint = replay.checkpoint()
  let _ = replay.skip(2)
  assert_true(@src.replay_is_at_end(replay))
  assert_true(replay.restore(checkpoint))
  assert_true(replay.position() == 1)
  assert_true(replay.status_name() == "running")
  assert_true(replay.seek(0))
  assert_true(replay.status_name() == "before-start")
  assert_true(!replay.seek(99))
}

///|
test "replay can halt and validate its consumed prefix" {
  let replay = @src.Replay::new([
    @src.Event::new("call", "read", "c1", Some("read"), None),
    @src.Event::new("result", "read", "c1", Some("read"), Some(true)),
  ])
  let _ = replay.next()
  replay.halt("manual inspection")
  assert_true(replay.done())
  assert_true(replay.status_name() == "halted")
  assert_true(replay.halted_reason() == Some("manual inspection"))
  assert_true(@src.replay_validate(replay, 2).length() == 1)
  assert_true(@src.replay_digest(replay).contains("call:read"))
}

///|
test "replay helpers find target events and expose JSON" {
  let replay = @src.Replay::new([
    @src.Event::new("call", "read", "c1", None, None),
    @src.Event::new("result", "read", "c1", None, Some(true)),
  ])
  let observation = @src.replay_until_kind(replay, "result")
  match observation {
    Some(_) => ()
    None => assert_true(false)
  }
  assert_true(observation.unwrap().call_id() == "c1")
  match @src.replay_until_call(replay, "missing") {
    Some(_) => assert_true(false)
    None => ()
  }
  assert_true(@src.replay_positions_for_kind(replay, "call") == [0])
  assert_true(@src.replay_status_json(replay).contains("consumed"))
}
