///|
test "published Mooncakes package evaluates a consumer trace" {
  assert_eq(@consumer.smoke_violation_count(), 0)
}
