"""The run's reading: every number a statute did not state, named once, with its convention.

Format (JSON; `Decode.reading` in Core decodes the same fields):
{"run": "<name>",
 "params": [{"name": "p.<name>", "value": 1.5, "unit": "s", "convention": "<where the value comes from>"}],
 "operationalizations": [], "aggregates": [{"word": "vehicle", "classes": ["ru.motor_vehicle", ...]}]}
Units: m, s, m/s, m/s2, deg, deg/s, ratio, count.
"""
from __future__ import annotations
import json
from pathlib import Path

TEMPLATE = {
    "run": "<run id>",
    "params": [],
    "operationalizations": [],
    "aggregates": [],
    "_fields": {
        "params": "name (p.<name>), value (number), unit (m|s|m/s|m/s2|deg|deg/s|ratio|count), convention (text)",
        "aggregates": "word (a legal aggregate such as 'vehicle'), classes (ru.* ids it covers)",
    },
}


class Reading:
    def __init__(self, path: Path):
        self.path = path
        self.data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"params": [], "aggregates": []}
        self.params = {p["name"]: p for p in self.data.get("params", [])}

    def has(self, name: str) -> bool:
        return name in self.params

    def names(self) -> set[str]:
        return set(self.params)

    def lean_json(self) -> str:
        """The reading as the Lean decoder expects it (no private fields)."""
        return json.dumps({k: v for k, v in self.data.items() if not k.startswith("_")}, ensure_ascii=False)


def write_template(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text(json.dumps(TEMPLATE, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
