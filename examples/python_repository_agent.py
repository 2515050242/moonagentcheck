"""Regression fixture for a repository assistant's observed read-and-write flow."""

from python_data_agent import Event, evaluate


def repository_assistant_events() -> list[Event]:
    return [
        Event("call", "read_file", "read-1", "inspect-readme"),
        Event("result", "read_file", "read-1", "inspect-readme", ok=True),
        Event("call", "apply_patch", "write-1", "update-readme"),
        Event("result", "apply_patch", "write-1", "update-readme", ok=True),
        Event("write-complete", "apply_patch", "write-1", "update-readme", ok=True),
    ]


def main() -> None:
    assert evaluate(repository_assistant_events()) == []
    print("repository assistant fixture passed")


if __name__ == "__main__":
    main()
