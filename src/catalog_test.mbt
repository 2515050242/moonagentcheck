///|
test "scenario catalog indexes names tags owners and event counts" {
  let catalog = ScenarioCatalog::new()
  let first = successful_data_read("read")
  let second = successful_repository_write("write")
  assert_true(catalog.add(first.as_entry()))
  assert_true(catalog.add(second.as_entry()))
  assert_true(!catalog.add(first.as_entry()))
  assert_true(catalog.len() == 2)
  assert_true(catalog.has_name("read"))
  match catalog.get("write") {
    Some(entry) => assert_true(entry.name() == "write")
    None => assert_true(false)
  }
  assert_true(catalog.with_tag("repository").length() == 1)
  assert_true(catalog.with_owner("moonagentcheck").length() == 2)
  assert_true(catalog.names() == ["read", "write"])
  assert_true(catalog_event_count(catalog) == 7)
  assert_true(catalog_tag_names(catalog).contains("side-effect"))
}

///|
test "catalog evaluates selected scenarios and produces results" {
  let catalog = builtin_scenario_catalog()
  assert_true(catalog.len() == 11)
  assert_true(
    catalog_is_complete(catalog, ["data-read-ok", "ticket-retry-failed"]),
  )
  assert_true(
    catalog_missing_names(catalog, ["data-read-ok", "not-present"]) ==
    ["not-present"],
  )
  let selected = catalog.select(["data-read-ok", "repository-read-ok"])
  assert_true(selected.length() == 2)
  let results = evaluate_catalog(catalog, 2)
  assert_true(results.length() == 11)
  assert_true(catalog_passed(results).length() > 0)
  assert_true(catalog_failed(results).length() > 0)
  assert_true(catalog_result_summary(results).scenario_count == 11)
}

///|
test "catalog tag selection stays independent" {
  let catalog = builtin_scenario_catalog()
  let ticket = catalog.scenarios_with_tag("ticket")
  assert_true(ticket.length() == 2)
  let ticket_results = catalog.evaluate_tag("ticket", 2)
  assert_true(ticket_results.length() == 2)
  let all_results = evaluate_catalog(catalog, 2)
  assert_true(
    catalog_results_for_tag(all_results, catalog, "data").length() == 3,
  )
  assert_true(catalog_json(catalog).contains("repository-read-ok"))
  assert_true(
    catalog_results_json(
      catalog_results_for_tag(all_results, catalog, "ticket"),
    ).contains("ticket"),
  )
}

///|
test "catalog policy evaluation retains metadata and allowlist failures" {
  let catalog = ScenarioCatalog::new()
  assert_true(
    catalog.add_scenario(
      Scenario::new("allowed", [
        Event::new("call", "read_file", "read-1", Some("read"), None),
        Event::new("result", "read_file", "read-1", Some("read"), Some(true)),
      ]),
      ["read"],
      "test",
      "allowed read",
    ),
  )
  assert_true(
    catalog.add_scenario(
      Scenario::new("denied", [
        Event::new("call", "write_file", "write-1", Some("write"), None),
        Event::new("result", "write_file", "write-1", Some("write"), Some(true)),
      ]),
      ["write"],
      "test",
      "denied write",
    ),
  )
  let policy = EvaluationPolicy::new(1, Some(["read_file"]))
  let scenarios = catalog.evaluate_with_policy(policy)
  assert_true(scenarios[0].passed)
  assert_true(!scenarios[1].passed)
  let tagged = catalog.evaluate_tag_with_policy("write", policy)
  assert_true(tagged.length() == 1)
  assert_true(!tagged[0].passed)
  let results = evaluate_catalog_with_policy(catalog, policy)
  assert_true(results[1].owner == "test")
  assert_true(violation_code(results[1].violations[0]) == "AGC012")
}
