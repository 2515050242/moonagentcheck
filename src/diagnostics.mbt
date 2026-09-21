///|
/// Severity assigned to an observed contract diagnostic.
pub enum DiagnosticSeverity {
  Info
  Warning
  Error
} derive(Eq, Debug)

///|
pub fn diagnostic_severity_name(severity : DiagnosticSeverity) -> String {
  match severity {
    Info => "info"
    Warning => "warning"
    Error => "error"
  }
}

///|
pub fn diagnostic_severity_rank(severity : DiagnosticSeverity) -> Int {
  match severity {
    Info => 1
    Warning => 2
    Error => 3
  }
}

///|
pub struct Diagnostic {
  code : String
  rule : String
  severity : DiagnosticSeverity
  event_index : Int
  message : String
  advice : String
}

///|
pub fn Diagnostic::new(
  code : String,
  rule : String,
  severity : DiagnosticSeverity,
  event_index : Int,
  message : String,
  advice : String,
) -> Diagnostic {
  { code, rule, severity, event_index, message, advice, }
}

///|
pub fn Diagnostic::is_error(diagnostic : Diagnostic) -> Bool {
  diagnostic.severity == Error
}

///|
pub fn Diagnostic::is_warning(diagnostic : Diagnostic) -> Bool {
  diagnostic.severity == Warning
}

///|
pub fn Diagnostic::is_info(diagnostic : Diagnostic) -> Bool {
  diagnostic.severity == Info
}

///|
pub fn Diagnostic::severity_name(diagnostic : Diagnostic) -> String {
  diagnostic_severity_name(diagnostic.severity)
}

///|
pub fn Diagnostic::render(diagnostic : Diagnostic) -> String {
  "[" +
  diagnostic.severity_name() +
  "] " +
  diagnostic.code +
  " " +
  diagnostic.rule +
  " at " +
  diagnostic.event_index.to_string() +
  ": " +
  diagnostic.message +
  " — " +
  diagnostic.advice
}

///|
pub fn advice_for_rule(rule : String) -> String {
  match rule {
    "orphan-result" =>
      "保留调用记录后再写入 result，并确认 call_id 来自同一调用。"
    "missing-result" =>
      "为每个 call 补充终态 result，或在 adapter 层标记取消。"
    "retry-limit" =>
      "为重试设置上限，并用 operation_id 固定同一业务动作。"
    "duplicate-side-effect" =>
      "在写入前检查 operation_id 是否已经完成，保证幂等。"
    "write-without-call" =>
      "只有在观察到对应 call 后才接受 write-complete。"
    "duplicate-call-id" => "为每次具体工具调用生成唯一 call_id。"
    "duplicate-result" =>
      "同一 call 只接受一个结果，重复回调应在 adapter 中去重。"
    "missing-operation-id" =>
      "写入事件必须带业务 operation_id，避免无法判断重试。"
    "failed-result" =>
      "失败结果不能继续驱动写入或下游副作用。"
    "write-without-successful-result" =>
      "写入前必须看到同一调用的 ok=true result。"
    "result-call-mismatch" =>
      "result 必须复用 call 的工具名和 operation_id。"
    "tool-not-allowed" =>
      "将实际工具加入显式策略，或确认该调用是否越权。"
    "invalid-event" => "在采集边界补齐非空 kind、tool 和 call_id。"
    "unknown-event-kind" =>
      "将框架事件映射到 call、result 或 write-complete。"
    "invalid-policy" => "重试策略必须是非负整数。"
    "missing-policy-source" =>
      "为策略上下文标记接入方配置来源，避免 allowlist 无法审计。"
    _ => "检查 adapter 的字段映射和该规则的行为契约。"
  }
}

///|
pub fn severity_for_rule(rule : String) -> DiagnosticSeverity {
  match rule {
    "invalid-event" => Error
    "unknown-event-kind" => Error
    "invalid-policy" => Error
    "missing-policy-source" => Error
    "write-without-call" => Error
    "write-without-successful-result" => Error
    "duplicate-side-effect" => Error
    "result-call-mismatch" => Error
    "orphan-result" => Warning
    "missing-result" => Warning
    "retry-limit" => Warning
    "duplicate-call-id" => Warning
    "duplicate-result" => Warning
    "missing-operation-id" => Warning
    "failed-result" => Info
    "tool-not-allowed" => Error
    _ => Warning
  }
}

///|
pub fn diagnostic_from_violation(violation : Violation) -> Diagnostic {
  Diagnostic::new(
    violation_code(violation),
    violation.rule,
    severity_for_rule(violation.rule),
    violation.event_index,
    violation.message,
    advice_for_rule(violation.rule),
  )
}

///|
pub fn diagnose(events : Array[Event], max_retries : Int) -> Array[Diagnostic] {
  evaluate(events, max_retries).map(diagnostic_from_violation)
}

///|
pub fn diagnose_with_policy(
  events : Array[Event],
  policy : EvaluationPolicy,
) -> Array[Diagnostic] {
  evaluate_with_policy(events, policy).map(diagnostic_from_violation)
}

///|
pub fn diagnostics_for_rule(
  diagnostics : Array[Diagnostic],
  rule : String,
) -> Array[Diagnostic] {
  diagnostics.filter(diagnostic => diagnostic.rule == rule)
}

///|
pub fn diagnostics_for_code(
  diagnostics : Array[Diagnostic],
  code : String,
) -> Array[Diagnostic] {
  diagnostics.filter(diagnostic => diagnostic.code == code)
}

///|
pub fn diagnostic_count(diagnostics : Array[Diagnostic]) -> Int {
  diagnostics.length()
}

///|
pub fn error_count(diagnostics : Array[Diagnostic]) -> Int {
  diagnostics.filter(diagnostic => diagnostic.is_error()).length()
}

///|
pub fn warning_count(diagnostics : Array[Diagnostic]) -> Int {
  diagnostics.filter(diagnostic => diagnostic.is_warning()).length()
}

///|
pub fn info_count(diagnostics : Array[Diagnostic]) -> Int {
  diagnostics.filter(diagnostic => diagnostic.is_info()).length()
}

///|
pub fn has_errors(diagnostics : Array[Diagnostic]) -> Bool {
  diagnostics.any(diagnostic => diagnostic.is_error())
}

///|
pub fn has_warnings(diagnostics : Array[Diagnostic]) -> Bool {
  diagnostics.any(diagnostic => diagnostic.is_warning())
}

///|
pub fn highest_severity(diagnostics : Array[Diagnostic]) -> DiagnosticSeverity {
  let mut rank = 0
  let mut severity = Info
  for diagnostic in diagnostics {
    let current = diagnostic_severity_rank(diagnostic.severity)
    if current > rank {
      rank = current
      severity = diagnostic.severity
    }
  }
  severity
}

///|
pub fn first_diagnostic(diagnostics : Array[Diagnostic]) -> Diagnostic? {
  if diagnostics.length() == 0 {
    None
  } else {
    Some(diagnostics[0])
  }
}

///|
pub fn first_error(diagnostics : Array[Diagnostic]) -> Diagnostic? {
  for diagnostic in diagnostics {
    if diagnostic.is_error() {
      return Some(diagnostic)
    }
  }
  None
}

///|
pub fn render_diagnostics(diagnostics : Array[Diagnostic]) -> String {
  let lines : Array[String] = []
  for diagnostic in diagnostics {
    lines.push(diagnostic.render())
  }
  lines.join("\n")
}

///|
pub struct DiagnosticSummary {
  total : Int
  errors : Int
  warnings : Int
  infos : Int
  highest : DiagnosticSeverity
}

///|
pub fn summarize_diagnostics(
  diagnostics : Array[Diagnostic],
) -> DiagnosticSummary {
  {
    total: diagnostic_count(diagnostics),
    errors: error_count(diagnostics),
    warnings: warning_count(diagnostics),
    infos: info_count(diagnostics),
    highest: highest_severity(diagnostics),
  }
}

///|
pub fn DiagnosticSummary::passed(summary : DiagnosticSummary) -> Bool {
  summary.errors == 0
}

///|
pub fn DiagnosticSummary::render(summary : DiagnosticSummary) -> String {
  "total=" +
  summary.total.to_string() +
  ", errors=" +
  summary.errors.to_string() +
  ", warnings=" +
  summary.warnings.to_string() +
  ", infos=" +
  summary.infos.to_string() +
  ", highest=" +
  diagnostic_severity_name(summary.highest)
}

///|
pub fn diagnose_scenario(
  scenario : Scenario,
  max_retries : Int,
) -> Array[Diagnostic] {
  diagnose(scenario.events, max_retries)
}

///|
pub struct ScenarioDiagnostics {
  name : String
  diagnostics : Array[Diagnostic]
  summary : DiagnosticSummary
}

///|
pub fn diagnose_scenarios(
  scenarios : Array[Scenario],
  max_retries : Int,
) -> Array[ScenarioDiagnostics] {
  let results : Array[ScenarioDiagnostics] = []
  for scenario in scenarios {
    let diagnostics = diagnose_scenario(scenario, max_retries)
    results.push({
      name: scenario.name,
      diagnostics,
      summary: summarize_diagnostics(diagnostics),
    })
  }
  results
}

///|
pub fn diagnostics_json(diagnostics : Array[Diagnostic]) -> String {
  Json::array(
    diagnostics.map(diagnostic => {
      Json::object({
        "code": Json(diagnostic.code),
        "rule": Json(diagnostic.rule),
        "severity": Json(diagnostic.severity_name()),
        "event_index": Json(diagnostic.event_index),
        "message": Json(diagnostic.message),
        "advice": Json(diagnostic.advice),
      })
    }),
  ).stringify()
}

///|
pub fn scenario_diagnostics_json(
  scenarios : Array[ScenarioDiagnostics],
) -> String {
  Json::array(
    scenarios.map(scenario => {
      Json::object({
        "name": Json(scenario.name),
        "passed": Json(scenario.summary.passed()),
        "summary": Json(scenario.summary.render()),
        "diagnostics": Json::array(
          scenario.diagnostics.map(diagnostic => {
            Json::object({
              "code": Json(diagnostic.code),
              "severity": Json(diagnostic.severity_name()),
              "rule": Json(diagnostic.rule),
              "event_index": Json(diagnostic.event_index),
              "message": Json(diagnostic.message),
            })
          }),
        ),
      })
    }),
  ).stringify()
}

///|
pub fn diagnostic_codes(diagnostics : Array[Diagnostic]) -> Array[String] {
  diagnostics.map(diagnostic => diagnostic.code)
}

///|
pub fn diagnostic_rules(diagnostics : Array[Diagnostic]) -> Array[String] {
  let rules : Array[String] = []
  for diagnostic in diagnostics {
    if !rules.contains(diagnostic.rule) {
      rules.push(diagnostic.rule)
    }
  }
  rules
}

///|
pub fn diagnostic_event_indices(diagnostics : Array[Diagnostic]) -> Array[Int] {
  diagnostics.map(diagnostic => diagnostic.event_index)
}

///|
pub fn diagnostics_are_ordered(diagnostics : Array[Diagnostic]) -> Bool {
  if diagnostics.length() < 2 {
    return true
  }
  for index in 1..<diagnostics.length() {
    if diagnostics[index].event_index < diagnostics[index - 1].event_index {
      return false
    }
  }
  true
}

///|
pub fn merge_diagnostics(
  first : Array[Diagnostic],
  second : Array[Diagnostic],
) -> Array[Diagnostic] {
  let merged : Array[Diagnostic] = []
  for diagnostic in first {
    merged.push(diagnostic)
  }
  for diagnostic in second {
    merged.push(diagnostic)
  }
  merged
}

///|
pub fn diagnostic_message_for_code(code : String) -> String {
  match code {
    "AGC001" => "result 没有对应 call"
    "AGC002" => "call 缺少 result"
    "AGC003" => "超过重试上限"
    "AGC004" => "重复副作用"
    "AGC005" => "写入缺少调用"
    "AGC006" => "重复 call_id"
    "AGC007" => "重复 result"
    "AGC008" => "写入缺少 operation_id"
    "AGC009" => "工具返回失败"
    "AGC010" => "写入没有成功结果前置"
    "AGC011" => "result 与 call 元数据不一致"
    "AGC012" => "工具不在允许列表"
    "AGC013" => "事件字段非法"
    "AGC014" => "事件类型未知"
    "AGC015" => "策略参数非法"
    "AGC016" => "写入与原始调用身份不一致"
    "AGC017" => "策略缺少配置来源"
    _ => "未知诊断编码"
  }
}
