///|
test "policy profiles expose stable defaults" {
  let read_only = EvaluationPolicy::new(
    1,
    Some(["read_file", "read_csv", "list_files"]),
  )
  match policy_profile_from_name("read-only") {
    Some(profile) => assert_true(policy_profile_name(profile) == "read-only")
    None => assert_true(false)
  }
  assert_true(policy_allows_tool(read_only, "read_file"))
  assert_true(!policy_allows_tool(read_only, "delete_file"))
  assert_true(policy_is_restricted(read_only))
  assert_true(policy_is_valid(read_only))
  match policy_profile_from_name("strict") {
    Some(profile) => assert_true(policy_profile_name(profile) == "strict")
    None => assert_true(false)
  }
  assert_true(policy_profile_from_name("unknown") == None)
}

///|
test "policy tools remain unique and can be edited" {
  let policy = EvaluationPolicy::new(2, Some(["read", "read", "write"]))
  assert_true(policy_tools(policy) == ["read", "write"])
  let added = policy_with_tool(policy, "list")
  assert_true(policy_tools(added) == ["read", "write", "list"])
  let removed = policy_without_tool(added, "read")
  assert_true(policy_tools(removed) == ["write", "list"])
  assert_true(policy_with_max_retries(policy, 4).max_retries == 4)
}

///|
test "allowlist set operations preserve left order" {
  assert_true(allowlist_union(["a", "b"], ["b", "c"]) == ["a", "b", "c"])
  assert_true(allowlist_intersection(["b", "a", "b"], ["a", "c"]) == ["a"])
  assert_true(allowlist_difference(["a", "b", "a"], ["a"]) == ["b"])
}

///|
test "policy decisions account for retry and permission boundaries" {
  let policy = EvaluationPolicy::new(1, Some(["read"]))
  let allowed = decide_tool(policy, "read", Some("load"), 1)
  let denied_tool = decide_tool(policy, "write", Some("save"), 1)
  let denied_retry = decide_tool(policy, "read", Some("load"), 2)
  assert_true(allowed.allowed)
  assert_true(allowed.remaining_retries == 0)
  assert_true(denied_tool.reason == "tool-not-allowed")
  assert_true(denied_retry.reason == "retry-limit")
}

///|
test "policy audit and comparison explain changes" {
  let policy = EvaluationPolicy::new(1, Some(["read"]))
  let events = [
    Event::new("call", "read", "c1", Some("op"), None),
    Event::new("call", "write", "c2", Some("op"), None),
  ]
  let audit = audit_policy(events, policy)
  assert_true(audit.total_calls == 2)
  assert_true(audit.denied_calls == 1)
  assert_true(audit.tool_denials == 1)
  let comparison = compare_policies(
    policy,
    EvaluationPolicy::new(2, Some(["read", "write"])),
  )
  assert_true(comparison.added_tools == ["write"])
  assert_true(comparison.same_retry_limit == false)
}
