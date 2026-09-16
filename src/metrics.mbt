///|
/// Per-tool counters provide a small, dependency-free observability layer.
pub struct ToolMetric {
  tool : String
  calls : Int
  results : Int
  successes : Int
  failures : Int
  unknowns : Int
  writes : Int
}

///|
pub fn ToolMetric::new(tool : String) -> ToolMetric {
  {
    tool,
    calls: 0,
    results: 0,
    successes: 0,
    failures: 0,
    unknowns: 0,
    writes: 0,
  }
}

///|
pub fn ToolMetric::total_outcomes(metric : ToolMetric) -> Int {
  metric.successes + metric.failures + metric.unknowns
}

///|
pub fn ToolMetric::success_rate(metric : ToolMetric) -> Int {
  if metric.results == 0 {
    0
  } else {
    metric.successes * 100 / metric.results
  }
}

///|
pub fn ToolMetric::has_failure(metric : ToolMetric) -> Bool {
  metric.failures > 0
}

///|
pub fn ToolMetric::render(metric : ToolMetric) -> String {
  metric.tool +
  " calls=" +
  metric.calls.to_string() +
  " results=" +
  metric.results.to_string() +
  " success-rate=" +
  metric.success_rate().to_string() +
  "% writes=" +
  metric.writes.to_string()
}

///|
pub struct OperationMetric {
  operation_id : String
  attempts : Int
  failed_attempts : Int
  successful_attempts : Int
  unknown_attempts : Int
  writes : Int
  duplicate_writes : Int
}

///|
pub fn OperationMetric::new(operation_id : String) -> OperationMetric {
  {
    operation_id,
    attempts: 0,
    failed_attempts: 0,
    successful_attempts: 0,
    unknown_attempts: 0,
    writes: 0,
    duplicate_writes: 0,
  }
}

///|
pub fn OperationMetric::is_retried(metric : OperationMetric) -> Bool {
  metric.attempts > 1
}

///|
pub fn OperationMetric::is_risky(metric : OperationMetric) -> Bool {
  metric.failed_attempts > 0 ||
  metric.duplicate_writes > 0 ||
  metric.unknown_attempts > 0
}

///|
pub fn OperationMetric::render(metric : OperationMetric) -> String {
  metric.operation_id +
  " attempts=" +
  metric.attempts.to_string() +
  " failed=" +
  metric.failed_attempts.to_string() +
  " writes=" +
  metric.writes.to_string() +
  " duplicate-writes=" +
  metric.duplicate_writes.to_string()
}

///|
pub struct TraceMetrics {
  event_count : Int
  call_count : Int
  result_count : Int
  write_count : Int
  successful_results : Int
  failed_results : Int
  unknown_results : Int
  tools : Array[ToolMetric]
  operations : Array[OperationMetric]
}

///|
fn metric_tool_index(metrics : Array[ToolMetric], tool : String) -> Int? {
  for index, metric in metrics {
    if metric.tool == tool {
      return Some(index)
    }
  }
  None
}

///|
fn metric_operation_index(
  metrics : Array[OperationMetric],
  operation_id : String,
) -> Int? {
  for index, metric in metrics {
    if metric.operation_id == operation_id {
      return Some(index)
    }
  }
  None
}

///|
fn ensure_tool_metric(metrics : Array[ToolMetric], tool : String) -> Int {
  match metric_tool_index(metrics, tool) {
    Some(index) => index
    None => {
      metrics.push(ToolMetric::new(tool))
      metrics.length() - 1
    }
  }
}

///|
fn ensure_operation_metric(
  metrics : Array[OperationMetric],
  operation_id : String,
) -> Int {
  match metric_operation_index(metrics, operation_id) {
    Some(index) => index
    None => {
      metrics.push(OperationMetric::new(operation_id))
      metrics.length() - 1
    }
  }
}

///|
pub fn collect_metrics(events : Array[Event]) -> TraceMetrics {
  let tools : Array[ToolMetric] = []
  let operations : Array[OperationMetric] = []
  let calls : Map[String, Int] = Map([])
  let completed_operations : Map[String, Int] = Map([])
  let mut call_count = 0
  let mut result_count = 0
  let mut write_count = 0
  let mut successes = 0
  let mut failures = 0
  let mut unknowns = 0
  for event in events {
    let tool_index = ensure_tool_metric(tools, event.tool)
    if event.kind == "call" {
      call_count = call_count + 1
      let tool = tools[tool_index]
      tools[tool_index] = { ..tool, calls: tool.calls + 1, }
      calls[event.call_id] = tool_index
      match event.operation_id {
        Some(operation_id) => {
          let operation_index = ensure_operation_metric(
            operations, operation_id,
          )
          let operation = operations[operation_index]
          operations[operation_index] = {
            ..operation,
            attempts: operation.attempts + 1,
          }
        }
        None => ()
      }
    } else if event.kind == "result" {
      result_count = result_count + 1
      let tool = tools[tool_index]
      let updated = { ..tool, results: tool.results + 1, }
      match event.ok {
        Some(true) => {
          successes = successes + 1
          tools[tool_index] = { ..updated, successes: updated.successes + 1, }
        }
        Some(false) => {
          failures = failures + 1
          tools[tool_index] = { ..updated, failures: updated.failures + 1, }
        }
        None => {
          unknowns = unknowns + 1
          tools[tool_index] = { ..updated, unknowns: updated.unknowns + 1, }
        }
      }
      match event.operation_id {
        Some(operation_id) => {
          let operation_index = ensure_operation_metric(
            operations, operation_id,
          )
          let operation = operations[operation_index]
          operations[operation_index] = match event.ok {
            Some(true) =>
              {
                ..operation,
                successful_attempts: operation.successful_attempts + 1,
              }
            Some(false) =>
              { ..operation, failed_attempts: operation.failed_attempts + 1, }
            None =>
              { ..operation, unknown_attempts: operation.unknown_attempts + 1, }
          }
        }
        None => ()
      }
    } else if event.kind == "write-complete" {
      write_count = write_count + 1
      let tool = tools[tool_index]
      tools[tool_index] = { ..tool, writes: tool.writes + 1, }
      match event.operation_id {
        Some(operation_id) => {
          let operation_index = ensure_operation_metric(
            operations, operation_id,
          )
          let operation = operations[operation_index]
          let previous = match completed_operations.get(operation_id) {
            Some(value) => value
            None => 0
          }
          let duplicate = if previous > 0 { 1 } else { 0 }
          completed_operations[operation_id] = previous + 1
          operations[operation_index] = {
            ..operation,
            writes: operation.writes + 1,
            duplicate_writes: operation.duplicate_writes + duplicate,
          }
        }
        None => ()
      }
    }
  }
  {
    event_count: events.length(),
    call_count,
    result_count,
    write_count,
    successful_results: successes,
    failed_results: failures,
    unknown_results: unknowns,
    tools,
    operations,
  }
}

///|
pub fn TraceMetrics::success_rate(metrics : TraceMetrics) -> Int {
  if metrics.result_count == 0 {
    0
  } else {
    metrics.successful_results * 100 / metrics.result_count
  }
}

///|
pub fn TraceMetrics::failure_rate(metrics : TraceMetrics) -> Int {
  if metrics.result_count == 0 {
    0
  } else {
    metrics.failed_results * 100 / metrics.result_count
  }
}

///|
pub fn TraceMetrics::tool(metrics : TraceMetrics, name : String) -> ToolMetric? {
  match metric_tool_index(metrics.tools, name) {
    Some(index) => Some(metrics.tools[index])
    None => None
  }
}

///|
pub fn TraceMetrics::operation(
  metrics : TraceMetrics,
  operation_id : String,
) -> OperationMetric? {
  match metric_operation_index(metrics.operations, operation_id) {
    Some(index) => Some(metrics.operations[index])
    None => None
  }
}

///|
pub fn TraceMetrics::risky_tools(metrics : TraceMetrics) -> Array[ToolMetric] {
  metrics.tools.filter(metric => metric.has_failure() || metric.writes > 0)
}

///|
pub fn TraceMetrics::risky_operations(
  metrics : TraceMetrics,
) -> Array[OperationMetric] {
  metrics.operations.filter(metric => metric.is_risky())
}

///|
pub fn TraceMetrics::render(metrics : TraceMetrics) -> String {
  "events=" +
  metrics.event_count.to_string() +
  " calls=" +
  metrics.call_count.to_string() +
  " results=" +
  metrics.result_count.to_string() +
  " writes=" +
  metrics.write_count.to_string() +
  " success-rate=" +
  metrics.success_rate().to_string() +
  "% failure-rate=" +
  metrics.failure_rate().to_string() +
  "%"
}

///|
pub fn tool_metrics_json(metrics : TraceMetrics) -> String {
  Json::array(
    metrics.tools.map(metric => {
      Json::object({
        "tool": Json(metric.tool),
        "calls": Json(metric.calls),
        "results": Json(metric.results),
        "successes": Json(metric.successes),
        "failures": Json(metric.failures),
        "unknowns": Json(metric.unknowns),
        "writes": Json(metric.writes),
        "success_rate": Json(metric.success_rate()),
      })
    }),
  ).stringify()
}

///|
pub fn operation_metrics_json(metrics : TraceMetrics) -> String {
  Json::array(
    metrics.operations.map(metric => {
      Json::object({
        "operation_id": Json(metric.operation_id),
        "attempts": Json(metric.attempts),
        "failed_attempts": Json(metric.failed_attempts),
        "successful_attempts": Json(metric.successful_attempts),
        "unknown_attempts": Json(metric.unknown_attempts),
        "writes": Json(metric.writes),
        "duplicate_writes": Json(metric.duplicate_writes),
        "risky": Json(metric.is_risky()),
      })
    }),
  ).stringify()
}

///|
pub fn trace_metrics_json(metrics : TraceMetrics) -> String {
  Json::object({
    "event_count": Json(metrics.event_count),
    "call_count": Json(metrics.call_count),
    "result_count": Json(metrics.result_count),
    "write_count": Json(metrics.write_count),
    "successful_results": Json(metrics.successful_results),
    "failed_results": Json(metrics.failed_results),
    "unknown_results": Json(metrics.unknown_results),
    "success_rate": Json(metrics.success_rate()),
    "failure_rate": Json(metrics.failure_rate()),
    "tools": Json::array(
      metrics.tools.map(metric => {
        Json::object({
          "tool": Json(metric.tool),
          "calls": Json(metric.calls),
          "results": Json(metric.results),
          "successes": Json(metric.successes),
          "failures": Json(metric.failures),
          "unknowns": Json(metric.unknowns),
          "writes": Json(metric.writes),
        })
      }),
    ),
    "operations": Json::array(
      metrics.operations.map(metric => {
        Json::object({
          "operation_id": Json(metric.operation_id),
          "attempts": Json(metric.attempts),
          "failed_attempts": Json(metric.failed_attempts),
          "successful_attempts": Json(metric.successful_attempts),
          "unknown_attempts": Json(metric.unknown_attempts),
          "writes": Json(metric.writes),
          "duplicate_writes": Json(metric.duplicate_writes),
        })
      }),
    ),
  }).stringify()
}
