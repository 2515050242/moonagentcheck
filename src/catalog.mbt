///|
/// Metadata makes a regression scenario discoverable without tying it to a
/// particular agent framework or test runner.
pub struct ScenarioEntry {
  scenario : Scenario
  tags : Array[String]
  owner : String
  description : String
}

///|
pub fn ScenarioEntry::new(
  scenario : Scenario,
  tags : Array[String],
  owner : String,
  description : String,
) -> ScenarioEntry {
  { scenario, tags: unique_strings(tags), owner, description, }
}

///|
pub fn ScenarioEntry::name(entry : ScenarioEntry) -> String {
  entry.scenario.name
}

///|
pub fn ScenarioEntry::has_tag(entry : ScenarioEntry, tag : String) -> Bool {
  entry.tags.contains(tag)
}

///|
pub fn ScenarioEntry::event_count(entry : ScenarioEntry) -> Int {
  entry.scenario.events.length()
}

///|
pub struct ScenarioCatalog {
  entries : Array[ScenarioEntry]
}

///|
pub fn ScenarioCatalog::new() -> ScenarioCatalog {
  { entries: [], }
}

///|
pub fn ScenarioCatalog::from_entries(
  entries : Array[ScenarioEntry],
) -> ScenarioCatalog {
  { entries, }
}

///|
pub fn ScenarioCatalog::len(catalog : ScenarioCatalog) -> Int {
  catalog.entries.length()
}

///|
pub fn ScenarioCatalog::is_empty(catalog : ScenarioCatalog) -> Bool {
  catalog.entries.length() == 0
}

///|
pub fn ScenarioCatalog::add(
  catalog : ScenarioCatalog,
  entry : ScenarioEntry,
) -> Bool {
  if catalog.has_name(entry.name()) {
    false
  } else {
    catalog.entries.push(entry)
    true
  }
}

///|
pub fn ScenarioCatalog::add_scenario(
  catalog : ScenarioCatalog,
  scenario : Scenario,
  tags : Array[String],
  owner : String,
  description : String,
) -> Bool {
  catalog.add(ScenarioEntry::new(scenario, tags, owner, description))
}

///|
pub fn ScenarioCatalog::entries(
  catalog : ScenarioCatalog,
) -> Array[ScenarioEntry] {
  catalog.entries
}

///|
pub fn ScenarioCatalog::names(catalog : ScenarioCatalog) -> Array[String] {
  catalog.entries.map(entry => entry.name())
}

///|
pub fn ScenarioCatalog::has_name(
  catalog : ScenarioCatalog,
  name : String,
) -> Bool {
  catalog.entries.any(entry => entry.name() == name)
}

///|
pub fn ScenarioCatalog::get(
  catalog : ScenarioCatalog,
  name : String,
) -> ScenarioEntry? {
  for entry in catalog.entries {
    if entry.name() == name {
      return Some(entry)
    }
  }
  None
}

///|
pub fn ScenarioCatalog::with_tag(
  catalog : ScenarioCatalog,
  tag : String,
) -> Array[ScenarioEntry] {
  catalog.entries.filter(entry => entry.has_tag(tag))
}

///|
pub fn ScenarioCatalog::with_owner(
  catalog : ScenarioCatalog,
  owner : String,
) -> Array[ScenarioEntry] {
  catalog.entries.filter(entry => entry.owner == owner)
}

///|
pub fn ScenarioCatalog::select(
  catalog : ScenarioCatalog,
  names : Array[String],
) -> Array[ScenarioEntry] {
  catalog.entries.filter(entry => names.contains(entry.name()))
}

///|
pub fn ScenarioCatalog::scenarios(catalog : ScenarioCatalog) -> Array[Scenario] {
  catalog.entries.map(entry => entry.scenario)
}

///|
pub fn ScenarioCatalog::scenarios_with_tag(
  catalog : ScenarioCatalog,
  tag : String,
) -> Array[Scenario] {
  catalog.with_tag(tag).map(entry => entry.scenario)
}

///|
pub fn ScenarioCatalog::evaluate(
  catalog : ScenarioCatalog,
  max_retries : Int,
) -> Array[ScenarioResult] {
  evaluate_scenarios(catalog.scenarios(), max_retries)
}

///|
pub fn ScenarioCatalog::evaluate_tag(
  catalog : ScenarioCatalog,
  tag : String,
  max_retries : Int,
) -> Array[ScenarioResult] {
  evaluate_scenarios(catalog.scenarios_with_tag(tag), max_retries)
}

///|
pub struct CatalogResult {
  name : String
  owner : String
  tags : Array[String]
  passed : Bool
  violations : Array[Violation]
}

///|
pub fn evaluate_catalog(
  catalog : ScenarioCatalog,
  max_retries : Int,
) -> Array[CatalogResult] {
  let results : Array[CatalogResult] = []
  for entry in catalog.entries {
    let violations = evaluate(entry.scenario.events, max_retries)
    results.push({
      name: entry.name(),
      owner: entry.owner,
      tags: entry.tags,
      passed: violations.length() == 0,
      violations,
    })
  }
  results
}

///|
pub fn catalog_result_summary(results : Array[CatalogResult]) -> SuiteSummary {
  let scenarios : Array[ScenarioResult] = []
  for result in results {
    scenarios.push({
      name: result.name,
      passed: result.passed,
      violations: result.violations,
    })
  }
  summarize_scenarios(scenarios)
}

///|
pub fn catalog_passed(results : Array[CatalogResult]) -> Array[CatalogResult] {
  results.filter(result => result.passed)
}

///|
pub fn catalog_failed(results : Array[CatalogResult]) -> Array[CatalogResult] {
  results.filter(result => !result.passed)
}

///|
pub fn catalog_results_for_tag(
  results : Array[CatalogResult],
  catalog : ScenarioCatalog,
  tag : String,
) -> Array[CatalogResult] {
  let names = catalog.with_tag(tag).map(entry => entry.name())
  results.filter(result => names.contains(result.name))
}

///|
pub fn catalog_tag_names(catalog : ScenarioCatalog) -> Array[String] {
  let tags : Array[String] = []
  for entry in catalog.entries {
    for tag in entry.tags {
      if !tags.contains(tag) {
        tags.push(tag)
      }
    }
  }
  tags
}

///|
pub fn catalog_owner_names(catalog : ScenarioCatalog) -> Array[String] {
  unique_strings(catalog.entries.map(entry => entry.owner))
}

///|
pub fn catalog_event_count(catalog : ScenarioCatalog) -> Int {
  let mut count = 0
  for entry in catalog.entries {
    count = count + entry.event_count()
  }
  count
}

///|
pub fn catalog_json(catalog : ScenarioCatalog) -> String {
  Json::array(
    catalog.entries.map(entry => {
      Json::object({
        "name": Json(entry.name()),
        "owner": Json(entry.owner),
        "description": Json(entry.description),
        "tags": Json::array(entry.tags.map(tag => Json(tag))),
        "event_count": Json(entry.event_count()),
      })
    }),
  ).stringify()
}

///|
pub fn catalog_results_json(results : Array[CatalogResult]) -> String {
  Json::array(
    results.map(result => {
      Json::object({
        "name": Json(result.name),
        "owner": Json(result.owner),
        "tags": Json::array(result.tags.map(tag => Json(tag))),
        "passed": Json(result.passed),
        "violation_count": Json(result.violations.length()),
        "violations": Json::array(
          result.violations.map(violation => {
            Json::object({
              "code": Json(violation_code(violation)),
              "rule": Json(violation.rule),
              "event_index": Json(violation.event_index),
            })
          }),
        ),
      })
    }),
  ).stringify()
}

///|
pub fn catalog_is_complete(
  catalog : ScenarioCatalog,
  required_names : Array[String],
) -> Bool {
  for name in required_names {
    if !catalog.has_name(name) {
      return false
    }
  }
  true
}

///|
pub fn catalog_missing_names(
  catalog : ScenarioCatalog,
  required_names : Array[String],
) -> Array[String] {
  required_names.filter(name => !catalog.has_name(name))
}

///|
pub fn catalog_duplicate_tags(catalog : ScenarioCatalog) -> Array[String] {
  let duplicates : Array[String] = []
  let seen : Array[String] = []
  for entry in catalog.entries {
    for tag in entry.tags {
      if seen.contains(tag) && !duplicates.contains(tag) {
        duplicates.push(tag)
      }
      if !seen.contains(tag) {
        seen.push(tag)
      }
    }
  }
  duplicates
}
