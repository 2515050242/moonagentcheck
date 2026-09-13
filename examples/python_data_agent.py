"""Small deterministic fixture used to validate the moonagentcheck event model."""

from dataclasses import dataclass
import json


@dataclass(frozen=True)
class Event:
    kind: str
    tool: str
    call_id: str
    operation_id: str | None = None
    ok: bool | None = None


def evaluate(events: list[Event], max_retries: int = 2) -> list[str]:
    """Return contract violations without contacting a model or a real tool."""
    violations: list[str] = []
    pending: set[str] = set()
    calls: dict[str, Event] = {}
    resolved: set[str] = set()
    successful: set[str] = set()
    attempts: dict[str, int] = {}
    completed: set[str] = set()

    for event in events:
        if event.kind == "call":
            if event.call_id in calls:
                violations.append(f"duplicate-call-id:{event.call_id}")
            calls[event.call_id] = event
            pending.add(event.call_id)
            if event.operation_id:
                attempts[event.operation_id] = attempts.get(event.operation_id, 0) + 1
                if attempts[event.operation_id] > max_retries:
                    violations.append(f"retry-limit:{event.operation_id}")
        elif event.kind == "result":
            call = calls.get(event.call_id)
            if event.call_id not in pending:
                violations.append(f"orphan-result:{event.call_id}")
            elif call is not None and (
                call.tool != event.tool or call.operation_id != event.operation_id
            ):
                resolved.add(event.call_id)
                successful.discard(event.call_id)
                violations.append(f"result-call-mismatch:{event.call_id}")
            elif event.call_id in resolved:
                violations.append(f"duplicate-result:{event.call_id}")
            else:
                resolved.add(event.call_id)
                if event.ok is False:
                    violations.append(f"failed-result:{event.call_id}")
                elif event.ok is True:
                    successful.add(event.call_id)
        elif event.kind == "write-complete":
            if event.call_id not in calls:
                violations.append(f"write-without-call:{event.call_id}")
            elif event.call_id not in successful:
                violations.append(f"write-without-successful-result:{event.call_id}")
            if not event.operation_id:
                violations.append(f"missing-operation-id:{event.call_id}")
            if event.operation_id in completed:
                violations.append(f"duplicate-side-effect:{event.operation_id}")
            completed.add(event.operation_id or event.call_id)

    violations.extend(f"missing-result:{call_id}" for call_id in sorted(pending - resolved))
    return violations


def main() -> None:
    events = [
        Event("call", "read_csv", "c1", "inspect-columns"),
        Event("result", "read_csv", "c1", "inspect-columns", ok=False),
        Event("call", "compute", "c2", "compute-total"),
        Event("write-complete", "ticket_write", "c3", "reply-42"),
        Event("write-complete", "ticket_write", "c4", "reply-42"),
    ]
    violations = evaluate(events)
    assert "failed-result:c1" in violations, "a missing-column error must not be accepted as success"
    assert "write-without-successful-result:c1" not in violations
    assert evaluate([
        Event("call", "read_csv", "match-1", "inspect-columns"),
        Event("result", "write_csv", "match-1", "inspect-columns", ok=True),
    ]) == ["result-call-mismatch:match-1"]
    assert evaluate([
        Event("call", "read_csv", "match-2", "inspect-columns"),
        Event("result", "read_csv", "match-2", "other-operation", ok=True),
    ]) == ["result-call-mismatch:match-2"]
    assert evaluate([
        Event("call", "read_csv", "match-3", "inspect-columns"),
        Event("result", "read_csv", "match-3", "inspect-columns", ok=True),
    ]) == []
    print(json.dumps({"violations": violations}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
