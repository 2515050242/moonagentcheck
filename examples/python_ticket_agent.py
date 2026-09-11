"""Regression fixture for a ticket agent that retries once before one write-back."""

from python_data_agent import Event, evaluate


def ticket_agent_events() -> list[Event]:
    return [
        Event("call", "update_ticket", "ticket-1", "reply-42"),
        Event("result", "update_ticket", "ticket-1", "reply-42", ok=False),
        Event("call", "update_ticket", "ticket-2", "reply-42"),
        Event("result", "update_ticket", "ticket-2", "reply-42", ok=True),
        Event("write-complete", "update_ticket", "ticket-2", "reply-42", ok=True),
    ]


def main() -> None:
    violations = evaluate(ticket_agent_events(), max_retries=2)
    assert violations == ["failed-result:ticket-1"]
    print("ticket agent fixture passed")


if __name__ == "__main__":
    main()
