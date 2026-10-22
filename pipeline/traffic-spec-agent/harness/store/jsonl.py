"""The run's audit files read strictly and written crash-safe: `rulings.jsonl`,
`aggregate_selection.jsonl`, `aggregate_certificates.jsonl`, `aggregate_input_manifest.json`, the
run's `reading.json`.

A non-empty line that is not a JSON object is a data-integrity failure, named by file and line,
never skipped: the run stops and the file is left as it is for diagnosis. A write replaces the file
through a temporary file in the same directory, flushed to disk and renamed over it, so a write cut
short leaves the previous file whole.
"""
from __future__ import annotations

import json
import os
import threading
from pathlib import Path

_LOCK = threading.Lock()


class DataIntegrityError(RuntimeError):
    """A run's audit file cannot be read as written: the run stops, the file is kept."""
    def __init__(self, path: Path, line: int | None, why: str):
        super().__init__(f"{path}" + (f":{line}" if line else "") + f": {why}")
        self.path, self.line, self.why = path, line, why


def read_strict(path: Path) -> list[dict]:
    if not path.exists():
        return []
    rows = []
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as e:
            raise DataIntegrityError(path, i, f"not JSON ({e.msg})")
        if not isinstance(row, dict):
            raise DataIntegrityError(path, i, "not a JSON object")
        rows.append(row)
    return rows


def read_json(path: Path, default):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise DataIntegrityError(path, e.lineno, f"not JSON ({e.msg})")


def write_atomic(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp-{os.getpid()}-{threading.get_ident()}")
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write(text)
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp, path)


def append_atomic(path: Path, row: dict) -> None:
    """Append one row: the existing rows are read strictly, so a damaged file is never extended."""
    with _LOCK:
        rows = read_strict(path)
        write_atomic(path, "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows + [row]))


def write_rows(path: Path, rows: list[dict]) -> None:
    with _LOCK:
        write_atomic(path, "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows))
