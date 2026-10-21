///|
test "published package accepts an explicitly successful Responses result" {
  let report = @json.parse(@consumer.success_report())
  match report {
    Json::Object(fields) => {
      assert_eq(fields.get("passed"), Some(Json(true)))
      assert_eq(fields.get("mapping_issues"), Some(Json::array([])))
      assert_eq(fields.get("violations"), Some(Json::array([])))
    }
    _ => fail("expected a report object")
  }
}

///|
test "published package rejects unknown outcome with AGC018" {
  let report = @json.parse(@consumer.unknown_report())
  match report {
    Json::Object(fields) => {
      assert_eq(fields.get("passed"), Some(Json(false)))
      assert_eq(fields.get("mapping_issues"), Some(Json::array([])))
      match fields.get("violations") {
        Some(Json::Array(values)) => {
          assert_eq(values.length(), 1)
          match values[0] {
            Json::Object(violation) => {
              assert_eq(violation.get("code"), Some(Json::string("AGC018")))
              assert_eq(
                violation.get("rule"),
                Some(Json::string("unknown-result")),
              )
              assert_eq(violation.get("event_index"), Some(Json::number(1)))
            }
            _ => fail("expected a violation object")
          }
        }
        _ => fail("expected violations array")
      }
    }
    _ => fail("expected a report object")
  }
}
