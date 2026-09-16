///|
/// Built-in scenario families provide repeatable examples for applications
/// that do not yet have a framework-specific adapter.
pub enum ScenarioKind {
  DataRead
  DataWrite
  RepositoryRead
  RepositoryWrite
  TicketRetry
  TicketDuplicateWrite
  MismatchedResult
  MissingResult
  OrphanResult
  PolicyDenied
} derive(Eq, Debug)

///|
pub fn scenario_kind_name(kind : ScenarioKind) -> String {
  match kind {
    DataRead => "data-read"
    DataWrite => "data-write"
    RepositoryRead => "repository-read"
    RepositoryWrite => "repository-write"
    TicketRetry => "ticket-retry"
    TicketDuplicateWrite => "ticket-duplicate-write"
    MismatchedResult => "mismatched-result"
    MissingResult => "missing-result"
    OrphanResult => "orphan-result"
    PolicyDenied => "policy-denied"
  }
}

///|
pub fn scenario_kind_from_name(name : String) -> ScenarioKind? {
  match name {
    "data-read" => Some(DataRead)
    "data-write" => Some(DataWrite)
    "repository-read" => Some(RepositoryRead)
    "repository-write" => Some(RepositoryWrite)
    "ticket-retry" => Some(TicketRetry)
    "ticket-duplicate-write" => Some(TicketDuplicateWrite)
    "mismatched-result" => Some(MismatchedResult)
    "missing-result" => Some(MissingResult)
    "orphan-result" => Some(OrphanResult)
    "policy-denied" => Some(PolicyDenied)
    _ => None
  }
}

///|
pub struct ScenarioSpec {
  kind : ScenarioKind
  scenario : Scenario
  expected_pass : Bool
  tags : Array[String]
  purpose : String
}

///|
pub fn ScenarioSpec::name(spec : ScenarioSpec) -> String {
  spec.scenario.name
}

///|
pub fn ScenarioSpec::events(spec : ScenarioSpec) -> Array[Event] {
  spec.scenario.events
}

///|
pub fn ScenarioSpec::as_entry(spec : ScenarioSpec) -> ScenarioEntry {
  ScenarioEntry::new(spec.scenario, spec.tags, "moonagentcheck", spec.purpose)
}

///|
fn spec(
  kind : ScenarioKind,
  name : String,
  events : Array[Event],
  expected_pass : Bool,
  tags : Array[String],
  purpose : String,
) -> ScenarioSpec {
  { kind, scenario: Scenario::new(name, events), expected_pass, tags, purpose, }
}

///|
pub fn successful_data_read(name : String) -> ScenarioSpec {
  spec(
    DataRead,
    name,
    [
      Event::new("call", "read_csv", "data-read-call", Some("inspect"), None),
      Event::new(
        "result",
        "read_csv",
        "data-read-call",
        Some("inspect"),
        Some(true),
      ),
    ],
    true,
    ["data", "read", "success"],
    "数据处理 Agent 完成读取并得到明确成功结果。",
  )
}

///|
pub fn failed_data_read(name : String) -> ScenarioSpec {
  spec(
    DataRead,
    name,
    [
      Event::new("call", "read_csv", "data-failed-call", Some("inspect"), None),
      Event::new(
        "result",
        "read_csv",
        "data-failed-call",
        Some("inspect"),
        Some(false),
      ),
    ],
    false,
    ["data", "read", "failure"],
    "数据列缺失时，失败结果不能被误当成成功。",
  )
}

///|
pub fn successful_data_write(name : String) -> ScenarioSpec {
  spec(
    DataWrite,
    name,
    [
      Event::new(
        "call",
        "transform_rows",
        "data-transform",
        Some("transform"),
        None,
      ),
      Event::new(
        "result",
        "transform_rows",
        "data-transform",
        Some("transform"),
        Some(true),
      ),
      Event::new("call", "write_csv", "data-write", Some("export"), None),
      Event::new(
        "result",
        "write_csv",
        "data-write",
        Some("export"),
        Some(true),
      ),
      Event::new(
        "write-complete",
        "write_csv",
        "data-write",
        Some("export"),
        Some(true),
      ),
    ],
    true,
    ["data", "write", "side-effect"],
    "数据处理 Agent 在成功转换后完成一次导出。",
  )
}

///|
pub fn successful_repository_read(name : String) -> ScenarioSpec {
  spec(
    RepositoryRead,
    name,
    [
      Event::new("call", "read_file", "repo-read", Some("inspect"), None),
      Event::new(
        "result",
        "read_file",
        "repo-read",
        Some("inspect"),
        Some(true),
      ),
      Event::new("call", "list_files", "repo-list", Some("inspect"), None),
      Event::new(
        "result",
        "list_files",
        "repo-list",
        Some("inspect"),
        Some(true),
      ),
    ],
    true,
    ["repository", "read", "success"],
    "仓库助手先读取目标文件并列出相关路径。",
  )
}

///|
pub fn successful_repository_write(name : String) -> ScenarioSpec {
  spec(
    RepositoryWrite,
    name,
    [
      Event::new(
        "call",
        "read_file",
        "repo-read-before-write",
        Some("edit"),
        None,
      ),
      Event::new(
        "result",
        "read_file",
        "repo-read-before-write",
        Some("edit"),
        Some(true),
      ),
      Event::new("call", "write_file", "repo-write", Some("edit"), None),
      Event::new("result", "write_file", "repo-write", Some("edit"), Some(true)),
      Event::new(
        "write-complete",
        "write_file",
        "repo-write",
        Some("edit"),
        Some(true),
      ),
    ],
    true,
    ["repository", "write", "side-effect"],
    "仓库助手读取成功后才写入，并将写入和业务动作关联。",
  )
}

///|
pub fn ticket_retry(name : String) -> ScenarioSpec {
  spec(
    TicketRetry,
    name,
    [
      Event::new(
        "call",
        "update_ticket",
        "ticket-attempt-1",
        Some("reply-42"),
        None,
      ),
      Event::new(
        "result",
        "update_ticket",
        "ticket-attempt-1",
        Some("reply-42"),
        Some(false),
      ),
      Event::new(
        "call",
        "update_ticket",
        "ticket-attempt-2",
        Some("reply-42"),
        None,
      ),
      Event::new(
        "result",
        "update_ticket",
        "ticket-attempt-2",
        Some("reply-42"),
        Some(true),
      ),
      Event::new(
        "write-complete",
        "update_ticket",
        "ticket-attempt-2",
        Some("reply-42"),
        Some(true),
      ),
    ],
    false,
    ["ticket", "retry", "failure"],
    "工单更新第一次失败、第二次成功，但报告保留失败尝试证据。",
  )
}

///|
pub fn ticket_duplicate_write(name : String) -> ScenarioSpec {
  spec(
    TicketDuplicateWrite,
    name,
    [
      Event::new(
        "call",
        "update_ticket",
        "ticket-write-1",
        Some("reply-42"),
        None,
      ),
      Event::new(
        "result",
        "update_ticket",
        "ticket-write-1",
        Some("reply-42"),
        Some(true),
      ),
      Event::new(
        "write-complete",
        "update_ticket",
        "ticket-write-1",
        Some("reply-42"),
        Some(true),
      ),
      Event::new(
        "write-complete",
        "update_ticket",
        "ticket-write-1",
        Some("reply-42"),
        Some(true),
      ),
    ],
    false,
    ["ticket", "idempotency", "side-effect"],
    "同一个工单业务动作被完成两次，应被识别为重复副作用。",
  )
}

///|
pub fn mismatched_result(name : String) -> ScenarioSpec {
  spec(
    MismatchedResult,
    name,
    [
      Event::new("call", "read_file", "mismatch-call", Some("read"), None),
      Event::new(
        "result",
        "write_file",
        "mismatch-call",
        Some("read"),
        Some(true),
      ),
    ],
    false,
    ["correlation", "metadata", "failure"],
    "result 复用了 call_id 但伪造了工具名，不能被当作成功。",
  )
}

///|
pub fn missing_result(name : String) -> ScenarioSpec {
  spec(
    MissingResult,
    name,
    [Event::new("call", "read_file", "missing-result-call", Some("read"), None)],
    false,
    ["completion", "failure"],
    "事件流结束时调用没有结果，说明采集链路不完整。",
  )
}

///|
pub fn orphan_result(name : String) -> ScenarioSpec {
  spec(
    OrphanResult,
    name,
    [
      Event::new(
        "result",
        "read_file",
        "orphan-result-call",
        Some("read"),
        Some(true),
      ),
    ],
    false,
    ["completion", "correlation", "failure"],
    "没有先出现 call 的 result 不能成为有效证据。",
  )
}

///|
pub fn policy_denied(name : String) -> ScenarioSpec {
  spec(
    PolicyDenied,
    name,
    [
      Event::new("call", "delete_file", "denied-call", Some("delete"), None),
      Event::new(
        "result",
        "delete_file",
        "denied-call",
        Some("delete"),
        Some(true),
      ),
    ],
    false,
    ["policy", "permission", "failure"],
    "只读策略下的删除工具调用应产生越权诊断。",
  )
}

///|
pub fn builtin_scenario_specs() -> Array[ScenarioSpec] {
  [
    successful_data_read("data-read-ok"),
    failed_data_read("data-read-failed"),
    successful_data_write("data-write-ok"),
    successful_repository_read("repository-read-ok"),
    successful_repository_write("repository-write-ok"),
    ticket_retry("ticket-retry-failed"),
    ticket_duplicate_write("ticket-duplicate-write"),
    mismatched_result("result-mismatch"),
    missing_result("missing-result"),
    orphan_result("orphan-result"),
    policy_denied("policy-denied"),
  ]
}

///|
pub fn builtin_scenario_catalog() -> ScenarioCatalog {
  let catalog = ScenarioCatalog::new()
  for spec in builtin_scenario_specs() {
    ignore(catalog.add(spec.as_entry()))
  }
  catalog
}

///|
pub fn builtin_scenarios() -> Array[Scenario] {
  builtin_scenario_specs().map(spec => spec.scenario)
}

///|
pub fn builtin_expected_passes() -> Array[Bool] {
  builtin_scenario_specs().map(spec => spec.expected_pass)
}

///|
pub fn builtin_scenario_names() -> Array[String] {
  builtin_scenario_specs().map(spec => spec.name())
}

///|
pub fn scenario_specs_for_tag(tag : String) -> Array[ScenarioSpec] {
  builtin_scenario_specs().filter(spec => spec.tags.contains(tag))
}

///|
pub fn scenario_events(kind : ScenarioKind) -> Array[Event] {
  match kind {
    DataRead => successful_data_read("data-read").events()
    DataWrite => successful_data_write("data-write").events()
    RepositoryRead => successful_repository_read("repository-read").events()
    RepositoryWrite => successful_repository_write("repository-write").events()
    TicketRetry => ticket_retry("ticket-retry").events()
    TicketDuplicateWrite => ticket_duplicate_write("ticket-duplicate").events()
    MismatchedResult => mismatched_result("mismatch").events()
    MissingResult => missing_result("missing").events()
    OrphanResult => orphan_result("orphan").events()
    PolicyDenied => policy_denied("denied").events()
  }
}

///|
pub fn evaluate_builtin_scenarios(max_retries : Int) -> Array[ScenarioResult] {
  evaluate_scenarios(builtin_scenarios(), max_retries)
}

///|
pub fn builtin_scenario_catalog_json() -> String {
  catalog_json(builtin_scenario_catalog())
}
