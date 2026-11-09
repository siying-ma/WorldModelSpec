"""Monitor verdicts joined per law, and fixed-denominator scoring of recordings against labels.

Reason: an alignment figure is only meaningful when every recording keeps a status, so a change that
makes a recording undecidable can never pass for an improvement, and the verdict join must be the
same wherever a recording is scored.

The label contract: a label judges the subject's conduct (the trace's `subject`, which the monitor
reports after identity merging) over the whole recording; `violated` means at least one occurrence
of the law's situation was violated, `compliant` that every occurrence complied, `not_applicable`
that the situation never arose for the subject.

Joins: a rule's verdict joins the episode verdicts of the groundings that bind its subject binder
(its first binder) to the subject; the other groundings are kept and reported, never joined. A
law's verdict joins the verdicts of all its expected rules; an unsupported rule is unknown; the
first of violated, unknown, compliant, not_applicable that occurs wins (an order for joining
evidence, not a severity).

Statuses, one per recording. Labelled recordings: `match`, `mismatch`, `unknown` (the law's verdict
is unknown; its blockers say why), `deadline` (a rule passed its time or memory limit), `crash` (the
monitor failed), `no_rule` (the law has no rule), `incomplete` (an expected rule of the law reported
no result), `contract_failed` (the subject the label judges cannot be found in the report: no
subject, more than one, or no subject binder). A recording without an explicit label is `unlabelled`
whatever happened to it; its verdict and any execution failure are kept beside the status, outside
the label denominator. A recording some of whose expected rules passed a limit or crashed keeps the
status of that failure and no verdict, whatever the others found: it is `partial` when some rule
finished, and keeps each finished rule's result beside the failed rules (`failed`, each with its
failure); a violation a finished rule proved is reported apart (`found_violation`, with the
completion and the status beside it), never a match and never a verdict of the law. Only `match`
counts as agreement. The labelled set is fixed by the labels, never inferred from a status, and a
judgment-call label (one whose verdict turns on a parameter the pipeline chooses) is counted apart
from the others.

Blockers. An unknown verdict keeps the monitor's reasons with their counts, and each reason becomes
a blocker: the reason, its class (the kind of reason, never by itself who is at fault), its evidence
and its handling. A handling names the party the evidence decides, and only then: `library` (a
repair can make the recording decided), `data` (the source does not deliver what the rule reads,
which is no proof that the rule reads the right thing), `harness` (a check that should have stopped
it did not), `aggregate` (the aggregate review path), `time_contract` (a window reaching past the
recording), `investigate` (neither side is shown). A recording can carry blockers of several
handlings; each is kept.

Window diagnosis. A truncated window keeps its blocker's class and handling (`history`,
`time_contract`); a plain-labelled unknown recording may in addition carry pieces of window evidence
(`diagnose_windows`), each a window operator Explain located, from its full structured report, as
carrying the truncation the verdict holds at unknown observations of the recording (the whole
recording is the range a label judges). A piece is eligible only when all of these hold: its Explain
ran on the current library and reading and its source map was built; it is located (its source, the
chain of concept calls and the binding traced); its operator is a metric window (`holdsFor`,
`atLast` behind, `within`, `untilWithin` ahead) reported in that direction; its length after
substitution is exactly a reading parameter `p.*` whose value and unit Explain read equal the
reading's, the unit the one of the window's measure and the value positive; its window was observed
not covered; and it is relevant: its grounding is one the label judges, and the grounding's segment
at its scoring observation is unknown with that window's reason, a reason the recording's blockers
carry. A blocker of that rule and reason with an eligible piece is `window_diagnosis` eligible: a
reason for a diagnostic repair, never proof that the library is wrong. The coverage says how many
unknown observations the located pieces explain; a partial coverage leaves an eligible piece
eligible for the positions it locates only; it never names the causes complete.
"""
from __future__ import annotations

import json
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass, field
from fractions import Fraction
from typing import Iterable

ORDER = ("violated", "unknown", "compliant", "not_applicable")
STATUSES = ("match", "mismatch", "unknown", "deadline", "crash", "no_rule", "incomplete", "contract_failed",
            "unlabelled")
HANDLINGS = ("library", "data", "harness", "aggregate", "time_contract", "investigate")

# The monitor's reason tags (`UnknownReason.tag`) by their constructor: the blocker class and handling.
REASONS = {
    "window_truncated": ("history", "time_contract"),
    "sampling_gap": ("source_sampling", "data"),
    "identity_gap": ("source_identity", "data"),
    "intention_missing": ("declaration", "data"),
    "assumption_missing": ("declaration", "data"),
    "parameter_missing": ("config", "harness"),
    "unbound_variable": ("static", "harness"),
    "malformed": ("static", "harness"),
    "out_of_range": ("static", "harness"),
    "division_by_zero": ("rule_semantic", "library"),
    "undefined": ("precondition_unmet", "investigate"),
    "composition_unknown": ("composition", "investigate"),
    "aggregate_unresolved": ("aggregate", "aggregate"),
}
FAILURES = ("deadline", "crash")
#: The metric window operators whose length a parameter bounds, each with its direction.
WINDOW_OPS = {"holdsFor": "look-back", "atLast": "look-back", "within": "look-ahead", "untilWithin": "look-ahead"}
#: The Core unit a window's length is read in, by the window's measure.
WINDOW_UNITS = {"time": "second", "path": "metre"}


def join(verdicts: Iterable[str]) -> str:
    vs = set(verdicts)
    return next((v for v in ORDER if v in vs), "not_applicable")


@dataclass
class GroundingResult:
    binding: dict
    verdict: str
    reasons: list[str] = field(default_factory=list)
    timeline: list = field(default_factory=list)
    unknowns: dict = field(default_factory=dict)        # reason tag → the observations it made unknown
    segments: list | None = None    # with `--segments`: [{from, to, verdict, reasons}], every observation once


@dataclass
class RuleResult:
    rule: str
    verdict: str                   # joined over the subject's groundings; "contract_failed" when it cannot be
    support: str
    absent: list[str] = field(default_factory=list)
    subject_binder: str | None = None
    subject: list = field(default_factory=list)                     # the subject track(s) the report names
    judged: list[GroundingResult] = field(default_factory=list)     # the groundings joined
    others: list[GroundingResult] = field(default_factory=list)     # every other grounding, reported only

    @property
    def groundings(self) -> int:
        return len(self.judged) + len(self.others)


def rule_results(monitor_json_lines: Iterable[str]) -> dict[str, RuleResult]:
    """Each rule of a monitor report (`monitor --json`): its verdict joined over the groundings that
    judge the subject, its support and absent atoms, and every grounding with its binding."""
    head: dict[str, dict] = {}
    rows: dict[str, list[GroundingResult]] = defaultdict(list)
    subj: dict | None = None
    segs: dict[tuple, list] = {}
    for line in monitor_json_lines:
        if not line.strip():
            continue
        d = json.loads(line)
        kind = d.get("kind")
        if kind == "rule":
            head[d["rule"]] = d
        elif kind == "grounding":
            ep = d.get("episode", {})
            rows[d["rule"]].append(GroundingResult(dict(d.get("grounding", {})), ep.get("verdict"),
                                                   list(ep.get("reasons", [])), list(d.get("timeline", [])),
                                                   dict(d.get("unknowns", {}))))
        elif kind == "segments":
            segs[(d["rule"], _key(d.get("grounding", {})))] = list(d.get("segments", []))
        elif kind == "subject":
            subj = d
    for r, gs in rows.items():
        for g in gs:
            g.segments = segs.get((r, _key(g.binding)))
    ego = list((subj or {}).get("ego", []))
    binders = (subj or {}).get("binders", {})
    out = {}
    for r, d in head.items():
        sup = d.get("support", "supported")
        binder = binders.get(r)
        judged = [g for g in rows[r] if len(ego) == 1 and binder is not None and g.binding.get(binder) == ego[0]]
        others = [g for g in rows[r] if g not in judged]
        if sup == "unsupported":
            verdict = "unknown"
        elif len(ego) != 1 or binder is None:
            verdict = "contract_failed"
        else:
            verdict = join(g.verdict for g in judged)
        out[r] = RuleResult(r, verdict, sup, list(d.get("absent", [])), binder, ego, judged, others)
    return out


def _key(binding: dict) -> str:
    return json.dumps(binding, sort_keys=True)


def _rule_dict(x: RuleResult) -> dict:
    """A rule's result as recorded: the segments of the groundings the label judges only."""
    d = asdict(x)
    for g in d["others"]:
        g.pop("segments", None)
    for g in d["judged"]:
        if g.get("segments") is None:
            g.pop("segments", None)
    return d


@dataclass
class Scored:
    recording_id: str
    law_id: str
    label: str | None
    verdict: str | None
    status: str
    rules: dict = field(default_factory=dict)
    note: str = ""
    failure: str | None = None          # deadline or crash, whether or not the recording is labelled
    judgment_call: bool = False
    blockers: list = field(default_factory=list)   # why the verdict is unknown, one entry per rule and reason
    failed: list = field(default_factory=list)     # the expected rules that did not finish: [{node, failure}]
    partial: bool = False           # some expected rule failed and some finished: `rules` holds the finished ones, no verdict
    found_violation: dict | None = None     # on a failed recording, the finished rules that proved a violation: {nodes, complete, status}
    windows: dict | None = None     # the window evidence of an unknown recording (`diagnose_windows`)

    def to_dict(self) -> dict:
        d = asdict(self)
        if d["windows"] is None:
            d.pop("windows")
        return d


def atom_of(tag: str, declared: dict[str, str]) -> str | None:
    """The atom an `absent_atom` tag names: the longest declared atom id whose Lean spelling the tag
    starts with (a tag is the atom's accessor, which may add a suffix: `dev_traffic_signal_shows`)."""
    hits = [a for a in declared if tag == a.replace(".", "_") or tag.startswith(a.replace(".", "_") + "_")]
    return max(hits, key=len) if hits else None


def _blocker(tag: str, declared: dict[str, str] | None) -> tuple[str, str, str]:
    """The class, handling and evidence of one reason tag."""
    kind, _, arg = tag.partition(":")
    if kind == "absent_atom":
        atom = atom_of(arg, declared or {})
        if atom is None:
            return "unmapped_atom", "investigate", f"`{arg}` names no atom the source declares"
        how = (declared or {})[atom]
        if how == "absent":
            return "source_unobserved", "data", f"the source declares {atom} absent; that the rule should read it is not shown"
        if how == "subject":
            return "source_subject_only", "data", f"the source declares {atom} for the subject only"
        return ("value_missing", "investigate",
                f"the source declares {atom} {how} and a value is missing for some entity; the ontology may allow "
                "none there (an entity its contract leaves without one), so the tag alone shows no data defect")
    if kind == "undefined":
        return (*REASONS[kind], f"`{arg}` has no value here: the data's geometry (a degenerate region, a tie) or a call "
                                "outside the primitive's precondition; the tag alone does not tell which")
    if kind in REASONS:
        cls, handling = REASONS[kind]
        return cls, handling, arg
    return "unexplained", "harness", f"unrecognised reason `{tag}`"


def blockers_of(results: dict[str, RuleResult], rules: list[str], declared: dict[str, str] | None) -> list[dict]:
    """Every blocker of the unknown rules among `rules`: per rule and reason, the observations it
    made unknown summed over the subject's unknown groundings. A blocker claims no instant: where a
    reason held is read from the rule's derivation."""
    out = []
    for r in rules:
        x = results[r]
        if x.verdict != "unknown":
            continue
        if x.support == "unsupported" and not x.judged:
            out.append({"rule": r, "reason": "unsupported", "class": "unsupported", "handling": "data",
                        "evidence": "the rule is unsupported: absent " + ", ".join(x.absent), "observations": None})
            continue
        acc: dict[str, dict] = {}
        for g in x.judged:
            if g.verdict != "unknown":
                continue
            if not g.reasons:
                acc.setdefault("", {"rule": r, "reason": "", "class": "unexplained", "handling": "harness",
                                    "evidence": "an unknown grounding gives no reason", "observations": None})
            for tag in g.reasons:
                cls, handling, ev = _blocker(tag, declared)
                b = acc.setdefault(tag, {"rule": r, "reason": tag, "class": cls, "handling": handling, "evidence": ev,
                                         "observations": 0})
                b["observations"] += int(g.unknowns.get(tag, 0))
        out.extend(acc.values())
    return out


def score(recording_id: str, law_id: str, label: str | None, results: dict[str, RuleResult] | None,
          law_of: dict[str, str], failure: str | None = None, judgment_call: bool = False,
          declared: dict[str, str] | None = None, failed: dict[str, str] | None = None) -> Scored:
    """The status of one recording. `results` are the monitor's results of the rules that finished
    (None when none did); `failed` maps each rule that did not to `deadline` or `crash`, and `failure`
    is the recording's own when no rule is named; `law_of` maps every rule the
    candidate registers to its law, so the law's expected rules are those it maps to the law;
    `declared` is the recording manifest's atom declarations, which classify its blockers.
    A failure decides the status (`deadline` over `crash`) and leaves no verdict; the finished
    rules' results are kept, and a violation one of them proved is reported apart."""
    def done(verdict, status, rules=None, note="", fail=None, blockers=()):
        return Scored(recording_id, law_id, label, verdict, "unlabelled" if label is None else status,
                      rules or {}, note, fail, judgment_call, list(blockers))

    failed = dict(failed or {})
    kinds = set(failed.values()) | ({failure} if failure is not None else set())
    if kinds:
        if not kinds <= set(FAILURES):
            raise ValueError(f"unknown failure {sorted(kinds - set(FAILURES))!r}")
        fail = "deadline" if "deadline" in kinds else "crash"
        got = results or {}
        kept = {r: got[r] for r in sorted(got) if law_of.get(r) == law_id and r not in failed}
        s = done(None, fail, {r: _rule_dict(x) for r, x in kept.items()}, fail=fail)
        s.failed = [{"node": r, "failure": k} for r, k in sorted(failed.items())]
        s.partial = bool(kept)
        proved = [r for r, x in kept.items() if x.verdict == "violated"]
        if proved:
            s.found_violation = {"nodes": proved, "complete": False, "status": s.status}
        return s
    expected = sorted(r for r, law in law_of.items() if law == law_id)
    if not expected:
        return done(None, "no_rule")
    got = results or {}
    rules = {r: _rule_dict(got[r]) for r in expected if r in got}
    missing = [r for r in expected if r not in got]
    if missing:
        return done(None, "incomplete", rules, f"no result for {', '.join(missing)}")
    mine = [got[r] for r in expected]
    if any(x.verdict == "contract_failed" for x in mine):
        return done(None, "contract_failed", rules, "the report names no single subject, or a rule has no subject binder")
    verdict = join(x.verdict for x in mine)
    blockers = blockers_of(got, expected, declared) if verdict == "unknown" else []
    if label is None:
        return done(verdict, "unlabelled", rules, blockers=blockers)
    if verdict == "unknown":
        return done(verdict, "unknown", rules, blockers=blockers)
    return done(verdict, "match" if verdict == label else "mismatch", rules)


def library_actionable(s: Scored) -> bool:
    """A plain-labelled unknown recording with a blocker whose evidence points at the library, or a
    blocker with an eligible window diagnosis."""
    return (s.status == "unknown" and s.label is not None and not s.judgment_call
            and any(b["handling"] == "library" or (b.get("window_diagnosis") or {}).get("eligible") for b in s.blockers))


def _q(x) -> Fraction | None:
    return Fraction(x["num"], x["den"]) if isinstance(x, dict) and "num" in x and x.get("den") else None


def _segment_at(g: dict, t: int) -> dict | None:
    return next((x for x in g.get("segments") or [] if x["from"] <= t <= x["to"]), None)


def window_piece(s: Scored, rule: str, binding: dict, piece: dict, params: dict[str, tuple[str, Fraction]]) -> str:
    """Why a located window piece of `rule`'s Explain for `binding` is not eligible ("" when it is):
    the conditions of the module's window diagnosis, checked on the structured report and on the
    recording's own segments."""
    op, tag = piece.get("op"), f"window_truncated:{piece.get('op')}"
    if not piece.get("located"):
        return f"source not located: {piece.get('not_located') or 'no source'}"
    if op not in WINDOW_OPS:
        return f"`{op}` is no metric window with a length of its own"
    if piece.get("direction") != WINDOW_OPS[op]:
        return f"`{op}` reads {WINDOW_OPS[op]}, the piece says {piece.get('direction')}"
    measure = piece.get("measure")
    if measure not in WINDOW_UNITS:
        return f"unknown measure {measure!r}"
    ln = piece.get("length") or {}
    name = ln.get("param")
    if not isinstance(name, str) or not name.startswith("p.") or ln.get("substituted") != name:
        return f"its length after substitution is `{ln.get('substituted')}`, not a reading parameter"
    value, unit = _q(ln.get("value")), ln.get("unit")
    if value is None or unit is None:
        return f"{name} has no value or unit in the reading Explain read"
    if unit != WINDOW_UNITS[measure]:
        return f"{name} is in {unit}, not the {WINDOW_UNITS[measure]} a {measure} window reads"
    if value <= 0:
        return f"{name} is not positive"
    if params.get(name) != (unit, value):
        return f"{name} as Explain read it differs from the current reading"
    ex = piece.get("example") or {}
    if not ex.get("requested") or not ex.get("observed") or ex["observed"].get("covered") is not False:
        return "its window is not shown truncated (requested and observed bounds, not covered)"
    sc = piece.get("scoring") or {}
    a, z = sc.get("first_ms"), sc.get("last_ms")
    if a is None or z is None or a > z:
        return "its scoring observations are not stated"
    judged = [g for g in (s.rules.get(rule) or {}).get("judged", []) if g.get("binding") == binding]
    seg = _segment_at(judged[0], a) if judged else None
    if seg is None or seg.get("verdict") != "unknown" or tag not in seg.get("reasons", []):
        return "the grounding the label judges is not unknown with this window's reason at its scoring observation"
    if not any(b["rule"] == rule and b["reason"] == tag for b in s.blockers):
        return f"no blocker of {rule} carries `{tag}`"
    return ""


def diagnose_windows(s: Scored, explained: list[dict], params: dict[str, tuple[str, Fraction]]) -> None:
    """The window diagnosis of an unknown recording: every piece of window evidence
    in the full structured Explain reports (`explained`: each {rule, binding, ok, windows, current,
    error}, `current` false when it was not made on the current library and reading), checked by
    `window_piece`; `s.windows` the pieces with their eligibility, the coverage and whether it is
    partial, and each `window_truncated` blocker its `window_diagnosis` (eligible, the pieces). A
    recording not unknown, or not plain-labelled, gets nothing; an Explain that
    failed or is stale gives no piece. The coverage counts the unknown observations, those with at
    least one located source (`with_located_source`), and those at which the cause search was
    complete (`search_complete`: nothing the Core reads was left unexamined, and every source found
    was located); it is partial unless every unknown observation's search was complete, every
    unknown grounding was explained and every piece and blocker is eligible. `params` are the
    reading's parameters, name → (Core unit tag, value in it)."""
    if s.status != "unknown" or s.label is None or s.judgment_call:
        return
    trunc = [b for b in s.blockers if b["reason"].startswith("window_truncated:")]
    if not trunc:
        return
    pieces, notes = [], []
    seen: dict[str, dict] = {}
    rules = sorted({b["rule"] for b in trunc})
    for e in (e for e in explained if e["rule"] in rules):
        rule, bind = e["rule"], e["binding"]
        w = e.get("windows")
        if not e.get("ok"):
            notes.append(f"{rule} for {bind}: Explain failed ({(e.get('error') or '')[:120]}); no piece")
            continue
        if not e.get("current"):
            notes.append(f"{rule} for {bind}: Explain was not made on the current library and reading; no piece")
            continue
        if not isinstance(w, dict):
            notes.append(f"{rule} for {bind}: Explain reported no windows; no piece")
            continue
        cov = seen.setdefault(rule, {"unknown": 0, "located": 0, "complete": 0, "groundings": 0})
        cov["unknown"] += int(w.get("unknown_instants", 0))
        cov["located"] += int(w.get("with_located_source", 0))
        cov["complete"] += int(w.get("search_complete", 0))
        cov["groundings"] += 1
        if w.get("source_map") != "ok":
            notes.append(f"{rule} for {bind}: source map not available ({w.get('source_map')})")
        notes += [f"{rule} for {bind}: walk cut: {c}" for c in w.get("cut", [])]
        for p in w.get("pieces", []):
            why = window_piece(s, rule, bind, p, params) if w.get("source_map") == "ok" else "source map not available"
            pieces.append({**p, "binding": p.get("binding", bind), "grounding": bind, "eligible": not why, "not_eligible": why})
    judged_unknown = {r: sum(1 for g in (x.get("judged") or []) if g.get("verdict") == "unknown") for r, x in s.rules.items()}
    for b in trunc:
        mine = [i for i, p in enumerate(pieces) if p["rule"] == b["rule"] and f"window_truncated:{p['op']}" == b["reason"] and p["eligible"]]
        b["window_diagnosis"] = {"eligible": bool(mine), "pieces": mine}
    unexplained_groundings = sum(max(0, judged_unknown.get(r, 0) - seen.get(r, {}).get("groundings", 0)) for r in rules)
    total = sum(seen.get(r, {}).get("unknown", 0) for r in rules)
    located = sum(seen.get(r, {}).get("located", 0) for r in rules)
    complete = sum(seen.get(r, {}).get("complete", 0) for r in rules)
    partial = bool(unexplained_groundings or complete < total or notes or any(not p["eligible"] for p in pieces)
                   or any(not b["window_diagnosis"]["eligible"] for b in trunc))
    s.windows = {"pieces": pieces, "partial": partial, "notes": notes,
                 "coverage": {"unknown_observations": total, "with_located_source": located, "search_complete": complete,
                              "groundings_not_explained": unexplained_groundings}}


def summary(scored: Iterable[Scored], expected: Iterable[str] | None = None) -> dict:
    """Counts per status, and agreement over the labelled recordings, judgment calls apart. With
    `expected` (every recording key of the fixed set), a missing or unexpected key is refused."""
    s = list(scored)
    keys = [x.recording_id for x in s]
    if len(keys) != len(set(keys)):
        raise ValueError("a recording is scored twice: the scoring key must be unique")
    if expected is not None:
        want = set(expected)
        if set(keys) != want:
            raise ValueError(f"the scored set differs from the fixed set: {len(want - set(keys))} missing, "
                             f"{len(set(keys) - want)} unexpected")

    def figures(xs: list[Scored]) -> dict:
        matched = sum(x.status == "match" for x in xs)
        return {"labelled": len(xs), "matched": matched, "agreement": matched / len(xs) if xs else None}

    labelled = [x for x in s if x.label is not None]
    counts = Counter(x.status for x in s)
    unknown = [x for x in s if x.verdict == "unknown"]
    return {"recordings": len(s), "counts": {k: counts.get(k, 0) for k in STATUSES},
            "blockers": {"handling": {h: sum(any(b["handling"] == h for b in x.blockers) for x in unknown) for h in HANDLINGS},
                         "class": dict(Counter(c for x in unknown for c in {b["class"] for b in x.blockers}))},
            "library_actionable": sum(library_actionable(x) for x in s),
            "unlabelled_failures": sum(x.label is None and x.failure is not None for x in s),
            "partial": sum(x.partial for x in s),
            "found_violation": sum(x.found_violation is not None for x in s),
            **figures([x for x in labelled if not x.judgment_call]),
            "judgment_call": figures([x for x in labelled if x.judgment_call])}
