"""Offline fixture for the documented OpenAI Responses function-call shape.

This is a fixture-side adapter only. The product contract remains implemented
and tested in MoonBit under src/responses_adapter.mbt.
"""

from python_data_agent import Event, evaluate


def adapt_response_items(items: list[dict[str, object]]) -> list[Event]:
    """Map ordered Responses items, preserving call identity and tool names."""
    calls: dict[str, Event] = {}
    events: list[Event] = []
    for index, item in enumerate(items):
        item_type = item.get("type")
        if item_type == "function_call":
            response_id = item.get("response_id")
            operation_id = item.get("operation_id")
            call_id = item.get("call_id")
            name = item.get("name")
            if not all(isinstance(value, str) and value for value in (response_id, call_id, name)):
                raise ValueError(f"item {index}: function_call needs response_id, call_id, and name")
            if operation_id is not None and not isinstance(operation_id, str):
                raise ValueError(f"item {index}: operation_id must be a string")
            event = Event("call", name, call_id, operation_id)
            calls[call_id] = event
            events.append(event)
        elif item_type == "function_call_output":
            call_id = item.get("call_id")
            status = item.get("status")
            outcome = item.get("outcome")
            if not isinstance(call_id, str) or not call_id:
                raise ValueError(f"item {index}: function_call_output needs call_id")
            if status not in {"in_progress", "completed", "incomplete"}:
                raise ValueError(f"item {index}: unsupported output status")
            if outcome is not None and not isinstance(outcome, bool):
                raise ValueError(f"item {index}: outcome must be boolean")
            call = calls.get(call_id)
            if call is None:
                raise ValueError(f"item {index}: output has no preceding call: {call_id}")
            ok = False if status == "incomplete" else outcome if status == "completed" else None
            events.append(Event("result", call.tool, call_id, call.operation_id, ok))
        else:
            raise ValueError(f"item {index}: unsupported Responses item type")
    return events


def main() -> None:
    events = adapt_response_items([
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
    ])
    assert events == [
        Event("call", "update_ticket", "call_42", "ticket-42"),
        Event("result", "update_ticket", "call_42", "ticket-42", True),
    ]
    assert evaluate(events) == []
    try:
        adapt_response_items([
            {"type": "function_call_output", "call_id": "unknown", "status": "completed"},
        ])
    except ValueError as error:
        assert "no preceding call" in str(error)
        print("OpenAI Responses fixture passed")
    else:
        raise AssertionError("output cannot invent a tool name")


if __name__ == "__main__":
    main()
