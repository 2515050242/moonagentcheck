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
      _ => input_error_report("expected a JSON array of Responses items")
    }
  } catch {
    _ => input_error_report("invalid JSON input")
  }
}
