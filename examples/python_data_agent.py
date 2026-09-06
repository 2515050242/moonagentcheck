"""Small deterministic fixture used to validate the AgentCheck event model."""

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
    attempts: dict[str, int] = {}
    completed: set[str] = set()

    for event in events:
        if event.kind == "call":
            pending.add(event.call_id)
            if event.operation_id:
                attempts[event.operation_id] = attempts.get(event.operation_id, 0) + 1
                if attempts[event.operation_id] > max_retries:
                    violations.append(f"retry-limit:{event.operation_id}")
        elif event.kind == "result":
            if event.call_id not in pending:
                violations.append(f"orphan-result:{event.call_id}")
            pending.discard(event.call_id)
        elif event.kind == "write-complete":
            if event.operation_id in completed:
                violations.append(f"duplicate-side-effect:{event.operation_id}")
            completed.add(event.operation_id or event.call_id)

    violations.extend(f"missing-result:{call_id}" for call_id in sorted(pending))
    return violations


def main() -> None:
    events = [
        Event("call", "read_csv", "c1", "inspect-columns"),
        Event("result", "read_csv", "c1", "inspect-columns", ok=False),
        Event("call", "compute", "c2", "compute-total"),
        Event("write-complete", "ticket_write", "c3", "reply-42"),
        Event("write-complete", "ticket_write", "c4", "reply-42"),
    ]
    print(json.dumps({"violations": evaluate(events)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

