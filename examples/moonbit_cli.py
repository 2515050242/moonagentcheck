"""Call the MoonBit command-line evaluator from the Python fixtures."""

import json
from pathlib import Path
import subprocess
from typing import Any


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]


def _run_moonbit(request: dict[str, Any] | list[dict[str, Any]]) -> dict[str, Any]:
    result = subprocess.run(
        ["moon", "run", "--quiet", "main", "--", json.dumps(request)],
        cwd=REPOSITORY_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError("MoonBit evaluator command failed")
    try:
        report = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError("MoonBit evaluator did not return JSON") from error
    if not isinstance(report, dict) or not isinstance(report.get("passed"), bool):
        raise RuntimeError("MoonBit evaluator returned an invalid report")
    return report


def _violations(report: dict[str, Any]) -> list[str]:
    violations = report.get("violations")
    if not isinstance(violations, list):
        raise RuntimeError("MoonBit evaluator report has no violations array")
    if report["passed"] != (len(violations) == 0):
        raise RuntimeError("MoonBit evaluator report has inconsistent pass status")
    converted: list[str] = []
    for violation in violations:
        if not isinstance(violation, dict):
            raise RuntimeError("MoonBit evaluator returned an invalid violation")
        rule = violation.get("rule")
        message = violation.get("message")
        if not isinstance(rule, str) or not isinstance(message, str):
            raise RuntimeError("MoonBit evaluator returned incomplete violation data")
        converted.append(f"{rule}:{message}")
    return converted


def evaluate_events(
    events: list[dict[str, Any]],
    *,
    max_retries: int = 2,
    tool_allowlist: list[str] | None = None,
) -> list[str]:
    report = _run_moonbit(
        {
            "events": events,
            "max_retries": max_retries,
            "tool_allowlist": tool_allowlist,
        }
    )
    if "input_error" in report:
        raise ValueError("MoonBit rejected the event request")
    return _violations(report)


def evaluate_responses_items(items: list[dict[str, Any]]) -> dict[str, Any]:
    report = _run_moonbit(items)
    if "mapping_issues" not in report or "violations" not in report:
        raise RuntimeError("MoonBit Responses adapter returned an incomplete report")
    return report
