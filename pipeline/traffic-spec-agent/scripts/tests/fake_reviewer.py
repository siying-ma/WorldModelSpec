"""A scripted behaviour-property reviewer for tests: no model and no solver. Its property sets are
given per law, one answer per call, in order (a set, or an exception to raise); its check reads the
mark (`-- <mark>`) the test library writes in each root rule's file, in whichever library is in
force (the run's or a candidate's), and returns the cells scripted for (law, mark). It records every
call it receives, with what it was shown."""
import hashlib
import json

from harness.model import nodeid
from harness.phases import behaviour_review as br
from harness.store import paths

NAME = "fake"


def prop(pid: str, category: str = "must_detect", clause: str = "C1") -> dict:
    return {"id": pid, "category": category, "clause": clause, "span_quote": "shall proceed slowly",
            "antecedent": {"atoms": ["kin.speed"]}, "expected": "violated" if category == "must_detect" else "not_violated"}


def pset(*records, clauses=("C1",), state: str = "ok", tag: str = "a", uncovered=(), assessments=()) -> dict:
    return {"state": state, "records": list(records), "clauses": [c if isinstance(c, dict) else {"id": c, "quote": "shall proceed slowly"}
                                                                  for c in clauses],
            "uncovered": list(uncovered), "screen_assessments": list(assessments),
            "reasons": [] if state == "ok" else ["schema invalid"],
            "calls": [{"label": "/review/bp_A", "request_sha": f"req-{tag}", "response_sha": f"resp-{tag}", "cost_usd": 0.0}]}


def cell(pid: str, verdicts=None, replay: str = "confirmed", status: str = "searched", antecedent: str = "nonempty",
         unknown: bool = False) -> dict:
    """A cell; `verdicts` is one scene's {rule: verdict} (none: no scene shown)."""
    return {"property": pid, "status": status, "antecedent": antecedent, "unknown_possible": unknown,
            "witnesses": [] if verdicts is None else [{"scene": "s1", "verdicts": dict(verdicts), "replay": replay}]}


def mark_of(rule: str) -> str | None:
    f = paths.LIBRARY / nodeid.rule_path(rule)
    if not f.is_file():
        return None
    for line in f.read_text(encoding="utf-8").splitlines():
        if line.startswith("-- "):
            return line[3:].strip()
    return None


class Fake:
    test_only = True                       # its rows carry the test credential: no production run accepts them

    def __init__(self, impl: str = "fake-v1"):
        self.impl = impl
        self.sets: dict[str, list] = {}
        self.cells: dict[tuple, object] = {}
        self.property_calls: list[tuple] = []
        self.check_calls: list[tuple] = []

    def digest(self) -> dict:
        h = lambda s: hashlib.sha256(s.encode()).hexdigest()[:16]
        return {"properties": h(self.impl + ":properties"), "check": h(self.impl + ":check")}

    def spec_key(self, run, law: str) -> str:
        return hashlib.sha256(json.dumps([law, self.digest()["properties"]]).encode()).hexdigest()[:24]

    def properties(self, run, law: str, workdir):
        self.property_calls.append((law,))
        answers = self.sets.get(law) or []
        if not answers:
            raise AssertionError(f"no scripted property set left for {law}")
        a = answers.pop(0)
        if isinstance(a, BaseException):
            raise a
        from pathlib import Path
        Path(workdir).mkdir(parents=True, exist_ok=True)
        (Path(workdir) / "response.json").write_text(json.dumps(a))     # what a production reviewer keeps of an answer
        return json.loads(json.dumps(a))

    def check(self, view, reading, law, roots, closure, records):
        marks = tuple(mark_of(r) for r in roots)
        self.check_calls.append((law, marks, tuple(closure), tuple(r["id"] for r in records)))
        got = self.cells.get((law, marks[0] if len(marks) == 1 else marks), self.cells.get(law))
        if isinstance(got, BaseException):
            raise got
        if callable(got):
            return got(roots, records)
        if got is None:
            raise AssertionError(f"no scripted cells for {law} {marks}")
        return json.loads(json.dumps(got))


FAKE = Fake()


def install(impl: str = "fake-v1") -> Fake:
    """A fresh scripted reviewer registered under `fake`."""
    global FAKE
    FAKE = Fake(impl)
    br.register(NAME, lambda: FAKE)
    return FAKE
