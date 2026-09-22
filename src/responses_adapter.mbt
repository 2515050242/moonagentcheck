///|
/// Output-item states used by the OpenAI Responses API function-call records.
///
/// `Completed` says that the API item finished, not that the application tool
/// succeeded. Adapters must preserve a separately observed outcome when one is
/// available.
pub enum ResponsesOutputStatus {
  InProgress
  Completed
  Incomplete
} derive(Eq, Debug)

///|
pub fn responses_in_progress() -> ResponsesOutputStatus {
  InProgress
}

///|
pub fn responses_completed() -> ResponsesOutputStatus {
  Completed
}

///|
pub fn responses_incomplete() -> ResponsesOutputStatus {
  Incomplete
}

///|
/// The subset of a Responses API item required to build an offline trace.
///
/// A function-call output only contains `call_id`; its tool name and logical
/// operation are recovered from the preceding function-call record. The
/// operation ID is supplied by the application telemetry envelope because the
/// Responses item schema does not define a business-operation identifier.
pub enum ResponsesItem {
  FunctionCall(String, String?, String, String)
  FunctionCallOutput(String, ResponsesOutputStatus, Bool?)
} derive(Eq, Debug)

///|
pub fn responses_function_call(
  response_id : String,
  operation_id : String?,
  call_id : String,
  name : String,
) -> ResponsesItem {
  FunctionCall(response_id, operation_id, call_id, name)
}

///|
pub fn responses_function_call_output(
  call_id : String,
  status : ResponsesOutputStatus,
  observed_outcome : Bool?,
) -> ResponsesItem {
  FunctionCallOutput(call_id, status, observed_outcome)
}

///|
/// A mapping issue is kept separate from contract violations because it means
/// the adapter could not produce a trustworthy Event at all.
pub struct ResponsesMappingIssue {
  item_index : Int
  message : String
} derive(Eq, Debug)

///|
/// Events and non-fatal mapping issues emitted while adapting a Responses
/// telemetry sequence.
pub struct ResponsesAdaptation {
  events : Array[Event]
  issues : Array[ResponsesMappingIssue]
}

///|
/// Convert an API output-item state and an executor-observed outcome to the
/// Event result status. A completed output without an observed outcome remains
/// unknown instead of being promoted to a successful tool result.
pub fn responses_output_ok(
  status : ResponsesOutputStatus,
  observed_outcome : Bool?,
) -> Bool? {
  match status {
    Incomplete => Some(false)
    InProgress => None
    Completed => observed_outcome
  }
}

///|
/// Adapt ordered OpenAI Responses function-call records into the core event
/// model without parsing JSON or contacting the API.
pub fn adapt_responses_items(
  items : Array[ResponsesItem],
) -> ResponsesAdaptation {
  let events : Array[Event] = []
  let issues : Array[ResponsesMappingIssue] = []
  let calls : Map[String, Event] = Map([])
  for index, item in items {
    match item {
      FunctionCall(response_id, operation_id, call_id, name) =>
        if response_id == "" {
          issues.push({
            item_index: index,
            message: "function call has empty response_id",
          })
        } else if call_id == "" {
          issues.push({
            item_index: index,
            message: "function call has empty call_id",
          })
        } else if name == "" {
          issues.push({
            item_index: index,
            message: "function call has empty name",
          })
        } else {
          let event = Event::new("call", name, call_id, operation_id, None)
          events.push(event)
          calls[call_id] = event
        }
      FunctionCallOutput(call_id, status, observed_outcome) =>
        if call_id == "" {
          issues.push({
            item_index: index,
            message: "function call output has empty call_id",
          })
        } else {
          match calls.get(call_id) {
            None =>
              issues.push({
                item_index: index,
                message: "function call output has no preceding function call: " +
                call_id,
              })
            Some(call) =>
              events.push(
                Event::new(
                  "result",
                  call.tool,
                  call_id,
                  call.operation_id,
                  responses_output_ok(status, observed_outcome),
                ),
              )
          }
        }
    }
  }
  { events, issues, }
}
