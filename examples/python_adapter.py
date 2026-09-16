"""Convert ordinary Python agent records into deterministic fixture events."""

from collections.abc import Iterable, Mapping
from typing import Any

from python_data_agent import Event, evaluate


class AdapterError(ValueError):
    """Raised when an application record cannot become an Event."""


def record_to_event(record: Mapping[str, Any]) -> Event:
    """Map a dictionary-shaped telemetry record to the shared event model."""
    required = ("kind", "tool", "call_id")
    missing = [field for field in required if field not in record]
    if missing:
        raise AdapterError(f"missing fields: {', '.join(missing)}")

    kind = record["kind"]
    tool = record["tool"]
    call_id = record["call_id"]
    if not all(isinstance(value, str) and value for value in (kind, tool, call_id)):
        raise AdapterError("kind, tool and call_id must be non-empty strings")
    if kind not in {"call", "result", "write-complete"}:
        raise AdapterError(f"unsupported event kind: {kind}")

    operation_id = record.get("operation_id")
    ok = record.get("ok")
    if operation_id is not None and not isinstance(operation_id, str):
        raise AdapterError(f"operation_id must be a string: {call_id}")
    if ok is not None and not isinstance(ok, bool):
        raise AdapterError(f"ok must be a boolean: {call_id}")
    return Event(kind, tool, call_id, operation_id, ok)


def adapt_records(records: Iterable[Mapping[str, Any]]) -> list[Event]:
    """Preserve telemetry order while converting each record with context."""
    events: list[Event] = []
    for index, record in enumerate(records):
        try:
            events.append(record_to_event(record))
        except AdapterError as error:
            raise AdapterError(f"record {index}: {error}") from error
    return events


def evaluate_records(
    records: Iterable[Mapping[str, Any]], max_retries: int = 2
) -> list[str]:
    """Adapt application records and run the same offline contract evaluator."""
    return evaluate(adapt_records(records), max_retries)


def main() -> None:
    records = [
        {"kind": "call", "tool": "read_csv", "call_id": "adapter-1", "operation_id": "read"},
        {
            "kind": "result",
            "tool": "read_csv",
            "call_id": "adapter-1",
            "operation_id": "read",
            "ok": True,
        },
    ]
    assert evaluate_records(records) == []
    try:
        evaluate_records([{"kind": "result", "tool": "read_csv"}])
    except AdapterError as error:
        assert "record 0" in str(error)
        print("python adapter passed")
    else:
        raise AssertionError("malformed records must be rejected before evaluation")


if __name__ == "__main__":
    main()
