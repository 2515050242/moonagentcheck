///|
fn main {
  let args = @env.args()
  match args.get(1) {
    Some(input) => println(responses_json_report(input))
    None => run_demo()
  }
}

///|
fn run_demo() -> Unit {
  let trace = @src.Trace::new()
  trace.call("read_file", "read-1", Some("inspect-config"))
  trace.result("read_file", "read-1", Some("inspect-config"), Some(true))
  trace.call("write_file", "write-1", Some("update-config"))
  trace.result("write_file", "write-1", Some("update-config"), Some(true))
  trace.write_complete("write_file", "write-1", Some("update-config"))
  trace.write_complete("write_file", "write-1", Some("update-config"))

  let policy = @src.EvaluationPolicy::new(1, Some(["read_file", "write_file"]))
  let context = @src.PolicyContext::new("main/demo-policy", policy)
  let violations = @src.evaluate_with_context(trace.events(), context)
  if violations.length() != 1 || @src.violation_code(violations[0]) != "AGC004" {
    println("unexpected contract evaluation")
    abort("demo assertion failed")
  }

  let results = @src.evaluate_scenarios(
    [@src.Scenario::new("duplicate-write", trace.events())],
    1,
  )
  println("MoonAgentCheck runnable demo")
  println(@src.evaluation_report_json(trace.events(), context))
  println(@src.scenario_results_json(results))
  println(@src.trace_metrics_json(@src.collect_metrics(trace.events())))
}

///|
fn json_string_field(item : Map[String, Json], key : String) -> String? {
  match item.get(key) {
    Some(Json::String(value)) => Some(value)
    _ => None
  }
}

///|
fn json_optional_string_field(
  item : Map[String, Json],
  key : String,
) -> String? {
  match item.get(key) {
    Some(Json::String(value)) => Some(value)
    _ => None
  }
}

///|
fn json_optional_bool_field(item : Map[String, Json], key : String) -> Bool? {
  match item.get(key) {
    Some(Json::True) => Some(true)
    Some(Json::False) => Some(false)
    _ => None
  }
}

///|
fn responses_item_from_json(value : Json) -> @src.ResponsesItem {
  match value {
    Json::Object(item) => {
      let item_type = json_string_field(item, "type")
      match item_type {
        Some("function_call") =>
          @src.responses_function_call(
            json_string_field(item, "response_id").unwrap_or(""),
            json_optional_string_field(item, "operation_id"),
            json_string_field(item, "call_id").unwrap_or(""),
            json_string_field(item, "name").unwrap_or(""),
          )
        Some("function_call_output") => {
          let call_id = json_string_field(item, "call_id").unwrap_or("")
          match json_string_field(item, "status") {
            Some("in_progress") =>
              @src.responses_function_call_output(
                call_id,
                @src.responses_in_progress(),
                json_optional_bool_field(item, "outcome"),
              )
            Some("completed") =>
              @src.responses_function_call_output(
                call_id,
                @src.responses_completed(),
                json_optional_bool_field(item, "outcome"),
              )
            Some("incomplete") =>
              @src.responses_function_call_output(
                call_id,
                @src.responses_incomplete(),
                json_optional_bool_field(item, "outcome"),
              )
            _ =>
              @src.responses_non_tool_item(
                "unsupported_function_call_output_status",
              )
          }
        }
        Some("message") => @src.responses_non_tool_item("message")
        Some("reasoning") => @src.responses_non_tool_item("reasoning")
        Some(other) => @src.responses_non_tool_item(other)
        None => @src.responses_non_tool_item("missing_item_type")
      }
    }
    _ => @src.responses_non_tool_item("invalid_item_shape")
  }
}

///|
fn event_from_json(value : Json) -> Result[@src.Event, String] {
  match value {
    Json::Object(item) => {
      let kind = json_string_field(item, "kind")
      let tool = json_string_field(item, "tool")
      let call_id = json_string_field(item, "call_id")
      let operation_id = match item.get("operation_id") {
        None | Some(Json::Null) => Ok(None)
        Some(Json::String(value)) => Ok(Some(value))
        Some(_) => Err("operation_id must be a string or null")
      }
      let ok = match item.get("ok") {
        None | Some(Json::Null) => Ok(None)
        Some(Json::True) => Ok(Some(true))
        Some(Json::False) => Ok(Some(false))
        Some(_) => Err("ok must be a boolean or null")
      }
      match (kind, tool, call_id, operation_id, ok) {
        (Some(kind), Some(tool), Some(call_id), Ok(operation_id), Ok(ok)) =>
          if kind == "call" || kind == "result" || kind == "write-complete" {
            if tool == "" || call_id == "" {
              Err("tool and call_id must be non-empty strings")
            } else {
              Ok(@src.Event::new(kind, tool, call_id, operation_id, ok))
            }
          } else {
            Err("unsupported event kind")
          }
        (_, _, _, Err(message), _) => Err(message)
        (_, _, _, _, Err(message)) => Err(message)
        _ => Err("event needs string kind, tool, and call_id fields")
      }
    }
    _ => Err("event must be a JSON object")
  }
}

///|
fn event_array_from_json(
  values : Array[Json],
) -> Result[Array[@src.Event], String] {
  let events : Array[@src.Event] = []
  let issues : Array[String] = []
  for index, value in values {
    match event_from_json(value) {
      Ok(event) => events.push(event)
      Err(message) => issues.push("event " + index.to_string() + ": " + message)
    }
  }
  if issues.length() == 0 {
    Ok(events)
  } else {
    Err(issues[0])
  }
}

///|
fn request_max_retries(object : Map[String, Json]) -> Result[Int32, String] {
  match object.get("max_retries") {
    None => Ok(2)
    Some(value) =>
      try {
        let retries : Int32 = @json.from_json(value)
        if retries < 0 {
          Err("max_retries must not be negative")
        } else {
          Ok(retries)
        }
      } catch {
        _ => Err("max_retries must be an integer")
      }
  }
}

///|
fn request_tool_allowlist(
  object : Map[String, Json],
) -> Result[Array[String]?, String] {
  match object.get("tool_allowlist") {
    None | Some(Json::Null) => Ok(None)
    Some(Json::Array(values)) => {
      let tools : Array[String] = []
      let issues : Array[String] = []
      for value in values {
        match value {
          Json::String(tool) => tools.push(tool)
          _ => issues.push("tool_allowlist entries must be strings")
        }
      }
      if issues.length() == 0 {
        Ok(Some(tools))
      } else {
        Err(issues[0])
      }
    }
    Some(_) => Err("tool_allowlist must be an array or null")
  }
}

///|
fn event_json_report(value : Json) -> String {
  match value {
    Json::Object(object) =>
      match object.get("events") {
        Some(Json::Array(values)) =>
          match event_array_from_json(values) {
            Ok(events) =>
              match
                (request_max_retries(object), request_tool_allowlist(object)) {
                (Ok(max_retries), Ok(tool_allowlist)) =>
                  @src.evaluation_report_json(
                    events,
                    @src.PolicyContext::new(
                      "cli/events-json",
                      @src.EvaluationPolicy::new(max_retries, tool_allowlist),
                    ),
                  )
                (Err(message), _) | (_, Err(message)) =>
                  input_error_report(message)
              }
            Err(message) => input_error_report(message)
          }
        _ => input_error_report("expected an events array")
      }
    _ => input_error_report("expected an event request object")
  }
}

///|
fn input_error_report(message : String) -> String {
  Json::object({
    "adapter": Json::string("openai-responses-function-call"),
    "passed": Json(false),
    "input_error": Json(message),
  }).stringify()
}

///|
pub fn responses_json_report(input : String) -> String {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Json::Array(values) =>
        @src.responses_evaluation_report_json(
          values.map(responses_item_from_json),
          @src.PolicyContext::new(
            "cli/responses-json",
            @src.EvaluationPolicy::new(1, None),
          ),
        )
      Json::Object(_) => event_json_report(parsed)
      _ =>
        input_error_report(
          "expected a Responses item array or an event request object",
        )
    }
  } catch {
    _ => input_error_report("invalid JSON input")
  }
}
