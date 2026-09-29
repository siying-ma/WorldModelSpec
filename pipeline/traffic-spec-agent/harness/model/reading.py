"""The run's reading: every number a statute did not state, named once, with its convention.

Format (JSON; `Decode.reading` in Core decodes the same fields):
{"run": "<name>",
 "params": [{"name": "p.<name>", "value": 1.5, "unit": "s", "convention": "<where the value comes from>"}],
   (a param whose value equals a figure a law of the corpus states also carries "figure_review": "<why it is a
    convention, not that figure>"; the doctor lists every such param until it does)
 "operationalizations": [], "aggregates": []}
Aggregates ("vehicle" → classes) are derived per run from the corpus definitions by the plan phase
(`harness/checks/aggregates.py`) into results/<run>/reading.json; an operator may declare one here to override.
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
        "params": "name (p.<name>), value (number), unit (m|s|m/s|m/s2|deg|deg/s|ratio|count), convention (text), "
                  "figure_review (optional: why a value that equals a figure some law states is a convention, not that figure)",
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

    def has_aggregate(self, word: str) -> bool:
        return any(a.get("word") == word and not a.get("derived") for a in self.data.get("aggregates", []))

    def with_aggregates(self, records: list[dict]) -> "Reading":
        """A copy with derived records added in memory (the draft check a planner runs)."""
        r = Reading.__new__(Reading); r.path = self.path
        r.data = json.loads(json.dumps(self.data))
        r.data["aggregates"] = list(r.data.get("aggregates", [])) + [
            {"word": x.get("word"), "classes": x.get("classes", []), "source": x.get("definition"), "derived": "draft"} for x in records]
        r.params = dict(self.params)
        return r

    def aggregate_words(self) -> set[str]:
        return {a.get("word") for a in self.data.get("aggregates", []) if a.get("word")}

    def expand(self, word: str, fuel: int | None = None) -> list[str]:
        """The `ru.*` ids a word covers, through other declared words (as `Reading.aggregate` in Core)."""
        aggs = {a["word"]: a.get("classes", []) for a in self.data.get("aggregates", []) if a.get("word")}
        fuel = len(aggs) + 1 if fuel is None else fuel
        if fuel == 0 or word not in aggs:
            return []
        out = []
        for m in aggs[word]:
            out += [m] if m.startswith("ru.") else (self.expand(m, fuel - 1) or [m])
        return out

    def lean_json(self) -> str:
        """The reading as the Lean decoder expects it (no private fields)."""
        return json.dumps({k: v for k, v in self.data.items() if not k.startswith("_")}, ensure_ascii=False)


def write_template(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text(json.dumps(TEMPLATE, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
