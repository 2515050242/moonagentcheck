"""Responses fixture checked by MoonBit's adapter and contract evaluator."""

import json
from pathlib import Path

from moonbit_cli import evaluate_responses_items


def violations(report: dict[str, object]) -> list[str]:
    raw_violations = report["violations"]
    assert isinstance(raw_violations, list)
    result: list[str] = []
    for violation in raw_violations:
        assert isinstance(violation, dict)
        rule = violation["rule"]
        message = violation["message"]
        assert isinstance(rule, str) and isinstance(message, str)
        result.append(f"{rule}:{message}")
    return result


def main() -> None:
    successful_items = [
        {
            "type": "function_call",
            "response_id": "resp_42",
            "operation_id": "ticket-42",
            "call_id": "call_42",
            "name": "update_ticket",
        },
        {
            "type": "function_call_output",
            "call_id": "call_42",
            "status": "completed",
            "outcome": True,
        },
    ]
    successful_report = evaluate_responses_items(successful_items)
    assert successful_report["passed"] is True
    assert violations(successful_report) == []

    mixed_report = evaluate_responses_items([
        {"type": "message", "role": "assistant", "content": []},
        {
            "type": "function_call",
            "response_id": "resp_mixed",
            "operation_id": "record-42",
            "call_id": "call_mixed",
            "name": "read_record",
        },
        {"type": "reasoning", "summary": []},
        {
            "type": "function_call_output",
            "call_id": "call_mixed",
            "status": "completed",
            "outcome": True,
        },
        {"type": "message", "role": "assistant", "content": []},
    ])
    assert mixed_report["passed"] is True
    assert mixed_report["mapped_event_count"] == 2

    fixture_path = Path(__file__).parent / "fixtures" / "responses-ticket-traces.json"
    fixtures = json.loads(fixture_path.read_text(encoding="utf-8"))
    assert len(fixtures) == 4
    for fixture in fixtures:
        report = evaluate_responses_items(fixture["items"])
        expected_error = fixture.get("expected_mapping_error")
        if expected_error is not None:
            issues = report["mapping_issues"]
            assert isinstance(issues, list) and issues, fixture["name"]
            assert issues[0]["message"] == expected_error, fixture["name"]
            assert report["passed"] is False, fixture["name"]
            continue

        expected = fixture["expected_violations"]
        assert violations(report) == expected, fixture["name"]
        assert report["passed"] is (len(expected) == 0), fixture["name"]

    unknown_report = evaluate_responses_items([
        {
            "type": "function_call",
            "response_id": "resp_unknown",
            "operation_id": "ticket-unknown",
            "call_id": "call_unknown",
            "name": "update_ticket",
        },
        {
            "type": "function_call_output",
            "call_id": "call_unknown",
            "status": "completed",
        },
    ])
    assert unknown_report["passed"] is False
    assert violations(unknown_report) == ["unknown-result:call_unknown"]

    duplicate_report = evaluate_responses_items([
        {
            "type": "function_call",
            "response_id": "resp_47",
            "operation_id": "export-47",
            "call_id": "call_47",
            "name": "write_file",
        },
        {
            "type": "function_call",
            "response_id": "resp_48",
            "operation_id": "notify-48",
            "call_id": "call_47",
            "name": "send_email",
        },
        {
            "type": "function_call_output",
            "call_id": "call_47",
            "status": "completed",
            "outcome": True,
        },
    ])
    assert duplicate_report["passed"] is False
    assert violations(duplicate_report) == ["duplicate-call-id:call_47"]

    unsupported_report = evaluate_responses_items([
        {"type": "message", "role": "assistant", "content": []},
        {"type": "web_search_call"},
    ])
    assert unsupported_report["passed"] is False
    issues = unsupported_report["mapping_issues"]
    assert isinstance(issues, list) and issues[0]["item_index"] == 1
    print("MoonBit Responses fixture passed")


if __name__ == "__main__":
    main()
