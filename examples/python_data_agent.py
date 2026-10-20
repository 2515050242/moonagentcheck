"""Python fixture records sent to the MoonBit contract evaluator."""

from dataclasses import asdict, dataclass

from moonbit_cli import evaluate_events


@dataclass(frozen=True)
class Event:
    kind: str
    tool: str
    call_id: str
    operation_id: str | None = None
    ok: bool | None = None


@dataclass(frozen=True)
class EvaluationPolicy:
    max_retries: int = 2
    tool_allowlist: frozenset[str] | None = None


def evaluate(events: list[Event], max_retries: int = 2) -> list[str]:
    """Return violations reported by the MoonBit implementation."""
    return evaluate_events(
        [asdict(event) for event in events], max_retries=max_retries
    )


def evaluate_with_policy(
    events: list[Event], policy: EvaluationPolicy
) -> list[str]:
    allowlist = (
        sorted(policy.tool_allowlist)
        if policy.tool_allowlist is not None
        else None
    )
    return evaluate_events(
        [asdict(event) for event in events],
        max_retries=policy.max_retries,
        tool_allowlist=allowlist,
    )


def main() -> None:
    events = [
        Event("call", "read_csv", "c1", "inspect-columns"),
        Event("result", "read_csv", "c1", "inspect-columns", ok=False),
        Event("call", "compute", "c2", "compute-total"),
        Event("write-complete", "ticket_write", "c3", "reply-42"),
        Event("write-complete", "ticket_write", "c4", "reply-42"),
    ]
    violations = evaluate(events)
    assert "failed-result:c1" in violations
    assert "duplicate-side-effect:reply-42" in violations
    assert evaluate([
        Event("call", "lookup", "unknown-1", "lookup-record"),
        Event("result", "lookup", "unknown-1", "lookup-record", ok=None),
    ]) == ["unknown-result:unknown-1"]
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
    assert evaluate_with_policy(
        [Event("call", "write_csv", "policy-1", "write")],
        EvaluationPolicy(tool_allowlist=frozenset({"read_csv"})),
    ) == ["tool-not-allowed:write_csv", "missing-result:policy-1"]
    assert evaluate_with_policy(
        [Event("call", "read_csv", "policy-2", "read")],
        EvaluationPolicy(tool_allowlist=frozenset()),
    ) == ["tool-not-allowed:read_csv", "missing-result:policy-2"]
    print("MoonBit-backed Python fixture passed")


if __name__ == "__main__":
    main()
