#!/usr/bin/env python3
"""
CLI tool to query the embedding retrieval service.

Example:
    python3 tools/retrieve_examples.py \
      --service-url http://127.0.0.1:8010/retrieve \
      --top-k 5 \
      --text-file /path/to/query.lean
Note, text-file is cleared after each query, so the same file can be reused for multiple queries.
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Query retrieval service and print top-k examples.")
    parser.add_argument(
        "--service-url",
        default="http://127.0.0.1:8010/retrieve",
        help="Retrieval API URL",
    )
    parser.add_argument("--top-k", type=int, default=5, help="Top-k results")
    parser.add_argument("--timeout", type=float, default=30.0, help="HTTP timeout (seconds)")
    parser.add_argument("--text-file", required=True, help="Read full query text from file")
    parser.add_argument(
        "--json",
        action="store_true",
        default=True,
        help="Print normalized JSON response (default: enabled)",
    )
    parser.add_argument(
        "--no-json",
        dest="json",
        action="store_false",
        help="Print human-readable output instead of JSON",
    )
    return parser


def _collect_texts(args: argparse.Namespace) -> list[str]:
    file_text = Path(args.text_file).read_text(encoding="utf-8")
    if not file_text.strip():
        raise ValueError("Input file is empty.")
    return [file_text]


def _clear_text_file(path: str) -> None:
    Path(path).write_text("", encoding="utf-8")


def _post_json(url: str, payload: dict[str, Any], timeout: float) -> dict[str, Any]:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json; charset=utf-8"},
        method="POST",
    )

    with urllib.request.urlopen(req, timeout=timeout) as resp:
        resp_body = resp.read().decode("utf-8")
        return json.loads(resp_body)


def _best_snippet(example: dict[str, Any]) -> str:
    for key in ("src", "text", "signature", "value"):
        val = example.get(key)
        if isinstance(val, str) and val.strip():
            one_line = " ".join(val.strip().split())
            return (one_line[:220] + "...") if len(one_line) > 220 else one_line
    return "(no snippet)"


def _sanitize_strategy(strategy: dict[str, Any]) -> dict[str, Any]:
    """Drop noisy fields from strategy metadata while preserving core refactoring info."""
    if not isinstance(strategy, dict):
        return {}

    blocked = {
        "median_of_median_relative_compilation_time_decrease",
        "members",
    }
    return {k: v for k, v in strategy.items() if k not in blocked}


def _normalize_response_shape(response: dict[str, Any]) -> dict[str, Any]:
    """
    Normalize service response for downstream consumers.

    - Remove `index` per result.
    - Rename `example` -> `refactoring_strategy`.
    - Remove noisy fields from strategy object.
    """
    if not isinstance(response, dict):
        return {"ok": False, "error": "Malformed response payload"}

    if not response.get("ok"):
        return {
            "ok": False,
            "error": response.get("error", "request failed"),
        }

    raw_results = response.get("results", [])
    if not isinstance(raw_results, list):
        raw_results = []

    normalized_results: list[dict[str, Any]] = []
    for entry in raw_results:
        if not isinstance(entry, dict):
            continue

        raw_strategy = entry.get("example")
        if not isinstance(raw_strategy, dict):
            raw_strategy = {}

        strategy = _sanitize_strategy(raw_strategy)
        if isinstance(strategy.get("strategy"), dict):
            strategy["strategy"] = _sanitize_strategy(strategy["strategy"])

        normalized_results.append(
            {
                "rank": entry.get("rank"),
                "score": entry.get("score"),
                "refactoring_strategy": strategy,
            }
        )

    return {
        "ok": True,
        "top_k": response.get("top_k"),
        "results": normalized_results,
    }


def _format_retrieved_strategies(retrieved: list[dict[str, Any]]) -> str:
    if not retrieved:
        return "No retrieved strategies available."

    lines: list[str] = []
    for idx, entry in enumerate(retrieved, start=1):
        example = (
            entry.get("refactoring_strategy", {})
            if isinstance(entry.get("refactoring_strategy"), dict)
            else {}
        )
        strategy = example.get("strategy", {}) if isinstance(example.get("strategy"), dict) else {}

        title = strategy.get("title") or example.get("title") or "Untitled"
        description = strategy.get("description") or example.get("description") or ""
        when_to_apply = strategy.get("when_to_apply") or example.get("when_to_apply") or ""
        the_fix = strategy.get("the_fix") or example.get("the_fix") or ""
        example_before = (
            strategy.get("abstract_example_before")
            or example.get("abstract_example_before")
            or ""
        )
        example_after = (
            strategy.get("abstract_example_after")
            or example.get("abstract_example_after")
            or ""
        )

        score = entry.get("score")

        lines.append(
            "\n".join(
                [
                    f"{idx}. Cosine Similarity Score: {score}",
                    f"**Title:**\n {title}\n",
                    f"**Description:**\n {description or _best_snippet(example)}\n",
                    f"**When to apply:**\n {when_to_apply or '(not provided)'}\n",
                    f"**The fix:**\n {the_fix or '(not provided)'}\n",
                    f"**Abstract example before:**\n {example_before or '(not provided)'}\n",
                    f"**Abstract example after:**\n {example_after or '(not provided)'}\n",
                    "",
                ]
            )
        )
    return "\n\n\n".join(lines).strip()


def _print_human(response: dict[str, Any]) -> None:
    if not response.get("ok"):
        print(f"ERROR: {response.get('error', 'request failed')}")
        return

    results = response.get("results", [])
    if not results:
        print("No results.")
        return

    print(f"Retrieved {len(results)} examples:\n")
    print(
        "Here are potentially useful proof-refactoring strategies matching your Lean query snippet, "
        "which may help reduce proof length.\n"
    )
    print(_format_retrieved_strategies(results))


def main() -> None:
    args = _build_parser().parse_args()

    try:
        texts = _collect_texts(args)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}")
        sys.exit(1)

    payload = {"texts": texts, "top_k": args.top_k}

    try:
        response = _post_json(args.service_url, payload, timeout=args.timeout)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        print(f"ERROR: HTTP {exc.code} - {detail}")
        sys.exit(1)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: failed to query service: {exc}")
        sys.exit(1)
    finally:
        try:
            _clear_text_file(args.text_file)
        except Exception as exc:  # noqa: BLE001
            print(f"WARNING: failed to clear input text file: {exc}", file=sys.stderr)

    normalized = _normalize_response_shape(response)

    if args.json:
        print(json.dumps(normalized, ensure_ascii=False, indent=2))
    else:
        _print_human(normalized)


if __name__ == "__main__":
    main()
