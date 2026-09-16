///|
test "metrics aggregate tools and result states" {
  let metrics = collect_metrics([
    Event::new("call", "read", "r1", Some("load"), None),
    Event::new("result", "read", "r1", Some("load"), Some(true)),
    Event::new("call", "read", "r2", Some("load"), None),
    Event::new("result", "read", "r2", Some("load"), Some(false)),
    Event::new("call", "write", "w1", Some("save"), None),
    Event::new("write-complete", "write", "w1", Some("save"), Some(true)),
  ])
  assert_true(metrics.event_count == 6)
  assert_true(metrics.call_count == 3)
  assert_true(metrics.result_count == 2)
  assert_true(metrics.write_count == 1)
  assert_true(metrics.successful_results == 1)
  assert_true(metrics.failed_results == 1)
  assert_true(metrics.success_rate() == 50)
  assert_true(metrics.failure_rate() == 50)
}

///|
test "metrics expose per-tool and per-operation risk" {
  let metrics = collect_metrics([
    Event::new("call", "ticket", "c1", Some("reply"), None),
    Event::new("result", "ticket", "c1", Some("reply"), Some(false)),
    Event::new("write-complete", "ticket", "c1", Some("reply"), Some(true)),
    Event::new("write-complete", "ticket", "c1", Some("reply"), Some(true)),
  ])
  let ticket = metrics.tool("ticket")
  match ticket {
    Some(metric) => {
      assert_true(metric.has_failure())
      assert_true(metric.writes == 2)
    }
    None => assert_true(false)
  }
  let operation = metrics.operation("reply")
  match operation {
    Some(metric) => {
      assert_true(metric.is_risky())
      assert_true(metric.duplicate_writes == 1)
    }
    None => assert_true(false)
  }
  assert_true(metrics.risky_tools().length() == 1)
  assert_true(metrics.risky_operations().length() == 1)
}

///|
test "metrics JSON includes tool and operation dimensions" {
  let metrics = collect_metrics([
    Event::new("call", "read", "c1", Some("load"), None),
    Event::new("result", "read", "c1", Some("load"), None),
  ])
  assert_true(tool_metrics_json(metrics).contains("success_rate"))
  assert_true(operation_metrics_json(metrics).contains("load"))
  assert_true(trace_metrics_json(metrics).contains("event_count"))
  assert_true(metrics.render().contains("failure-rate"))
}
