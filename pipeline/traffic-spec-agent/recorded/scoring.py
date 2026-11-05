"""Monitor verdicts joined per law, and fixed-denominator scoring of recordings against labels.

Reason: an alignment figure is only meaningful when every recording keeps a status, so a change that
makes a recording undecidable can never pass for an improvement, and the verdict join must be the
same wherever a recording is scored.

The label contract: a label judges the subject's conduct (the trace's `subject`, which the monitor
reports after identity merging) over the whole recording (contract v1), or over the label's scoring
interval (contract v2); `violated` means at least one occurrence of the law's situation was violated,
`compliant` that every occurrence complied, `not_applicable` that the situation never arose for the
subject.

Scoring interval (v2). The monitor evaluates the whole trace and reports, per grounding, its
segments: the runs of consecutive observations with one verdict and one set of unknown reasons
(`monitor --json --segments`). `within` keeps of each grounding only the observations inside the
closed interval `[start_ms, end_ms]` and joins those alone, so the grounding's verdict, its reasons,
its unknown counts and its timeline are the interval's: a violation outside the interval does not
count, one inside still wins over an unknown, and an unknown met only outside (a look-back window
truncated at the trace start, before the interval) is not joined. The trace is never cut before it
is evaluated: an observation inside the interval reads its history and its future in the whole
trace. A label whose interval cannot be used is `label_unverified`; the whole-recording verdict is
kept beside an interval score as a diagnosis and never counted, and no summary joins scores of the
two contracts.

Joins: a rule's verdict joins the episode verdicts of the groundings that bind its subject binder
(its first binder) to the subject; the other groundings are kept and reported, never joined. A
law's verdict joins the verdicts of all its expected rules; an unsupported rule is unknown; the
first of violated, unknown, compliant, not_applicable that occurs wins (an order for joining
evidence, not a severity).

Statuses, one per recording. Labelled recordings: `match`, `mismatch`, `unknown` (the law's verdict
is unknown; its blockers say why), `deadline` (a rule passed its time or memory limit), `crash` (the monitor failed), `no_rule` (the
law has no rule), `incomplete` (an expected rule of the law reported no result), `contract_failed`
(the subject the label judges cannot be found in the report: no subject, more than one, or no
subject binder), `label_unverified` (v2: the label's scoring interval is missing, malformed, off the
trace or unconfirmed; it is not evaluated, never a match, and keeps its place among the labels). A recording without an explicit label is `unlabelled` whatever happened to it;
its verdict and any execution failure are kept beside the status, outside the label denominator.
A recording some of whose expected rules passed a limit or crashed keeps the status of that failure
and no verdict, whatever the others found: it is `partial` when some rule finished, and keeps each
finished rule's result (under v2, its interval's) beside the failed rules (`failed`, each with its
failure); a violation a finished rule proved is reported apart (`found_violation`, with the
completion and the status beside it), never a match and never a verdict of the law.
Only `match` counts as agreement. The labelled set is fixed by the labels, never inferred from a
status, and a judgment-call label (one whose verdict turns on a parameter the pipeline chooses) is
counted apart from the others.

Blockers. An unknown verdict keeps the monitor's reasons with their counts, and each reason becomes a
blocker: the reason, its class (the kind of reason, never by itself who is at fault), its evidence
and its handling. A handling names the party the evidence decides, and only then: `library` (a
repair can make the recording decided), `data` (the source does not deliver what the rule reads,
which is no proof that the rule reads the right thing), `harness` (a check that should have stopped
it did not), `aggregate` (the aggregate review path), `time_contract` (a window reaching past the
recording, held until the scoring interval of a label is fixed), `investigate` (neither side is
shown). A recording can carry blockers of several handlings; each is kept.
"""
from __future__ import annotations

import json
from bisect import bisect_left, bisect_right
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass, field
from typing import Iterable

ORDER = ("violated", "unknown", "compliant", "not_applicable")
STATUSES = ("match", "mismatch", "unknown", "deadline", "crash", "no_rule", "incomplete", "contract_failed",
            "unlabelled")
#: The statuses of interval scoring (contract v2): those of v1 and an unusable label.
STATUSES_V2 = STATUSES + ("label_unverified",)
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


def _between(times: list[int], a: int, b: int) -> list[int]:
    return times[bisect_left(times, a):bisect_right(times, b)]


def _clip(g: GroundingResult, start_ms: int, end_ms: int, times: list[int]) -> GroundingResult:
    if g.segments is None:
        raise ValueError("the report carries no reason-carrying segments (`monitor --segments`)")
    inside, segs = _between(times, start_ms, end_ms), []
    for sg in g.segments:
        ts = _between(times, max(sg["from"], start_ms), min(sg["to"], end_ms))
        if ts:
            segs.append({"from": ts[0], "to": ts[-1], "verdict": sg["verdict"], "reasons": list(sg.get("reasons", [])),
                         "observations": len(ts)})
    if sum(x["observations"] for x in segs) != len(inside):
        raise ValueError(f"a grounding's segments do not cover the scoring interval once ({g.binding})")
    unknown = [x for x in segs if x["verdict"] == "unknown"]
    reasons = list(dict.fromkeys(t for x in unknown for t in x["reasons"]))
    counts = {t: sum(x["observations"] for x in unknown if t in x["reasons"]) for t in reasons}
    return GroundingResult(dict(g.binding), join(x["verdict"] for x in segs), reasons,
                           [{"from": x["from"], "to": x["to"], "verdict": x["verdict"]} for x in segs], counts, segs)


def within(results: dict[str, RuleResult], start_ms: int, end_ms: int, times: list[int]) -> dict[str, RuleResult]:
    """The rule results restricted to the scoring interval `[start_ms, end_ms]` of a trace whose
    observation times are `times` (sorted): every grounding keeps only its segments' observations
    inside the interval, its verdict, reasons and unknown counts joined over them alone; a rule's
    verdict joins its subject's restricted groundings, as `rule_results` does. A rule without
    groundings (unsupported) or without a single subject keeps its verdict. A grounding whose
    segments are missing or do not cover the interval is refused (`ValueError`)."""
    out = {}
    for r, x in results.items():
        judged = [_clip(g, start_ms, end_ms, times) for g in x.judged]
        others = [_clip(g, start_ms, end_ms, times) for g in x.others]
        verdict = x.verdict if x.verdict == "contract_failed" or x.support == "unsupported" else join(g.verdict for g in judged)
        out[r] = RuleResult(r, verdict, x.support, list(x.absent), x.subject_binder, list(x.subject), judged, others)
    return out


def _rule_dict(x: RuleResult) -> dict:
    d = asdict(x)
    for g in d["judged"] + d["others"]:
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
    scope: dict | None = None       # v2: the scoring interval, its source and the whole-recording verdict (a diagnosis)
    failed: list = field(default_factory=list)     # the expected rules that did not finish: [{node, failure}]
    partial: bool = False           # some expected rule failed and some finished: `rules` holds the finished ones, no verdict
    found_violation: dict | None = None     # on a failed recording, the finished rules that proved a violation: {nodes, complete, status}

    def to_dict(self) -> dict:
        d = asdict(self)
        if d["scope"] is None:
            d.pop("scope")
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
    made unknown summed over the subject's unknown groundings. Under a scoring interval the results
    are those `within` restricted to it, so a reason held only outside the interval is no blocker and
    the counts are the interval's. A blocker claims no instant: where a reason held is read from the
    rule's derivation."""
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
          declared: dict[str, str] | None = None, scope: dict | None = None,
          failed: dict[str, str] | None = None) -> Scored:
    """The status of one recording. `results` are the monitor's results of the rules that finished
    (None when none did); `failed` maps each rule that did not to `deadline` or `crash`, and `failure`
    is the recording's own when no rule is named; `law_of` maps every rule the
    candidate registers to its law, so the law's expected rules are those it maps to the law;
    `declared` is the recording manifest's atom declarations, which classify its blockers; `scope`
    (v2) is the label's scoring interval, the results being already restricted to it (`within`).
    A failure decides the status (`deadline` over `crash`) and leaves no verdict; the finished
    rules' results are kept, and a violation one of them proved is reported apart."""
    def done(verdict, status, rules=None, note="", fail=None, blockers=()):
        return Scored(recording_id, law_id, label, verdict, "unlabelled" if label is None else status,
                      rules or {}, note, fail, judgment_call, list(blockers), scope)

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


def unverified(recording_id: str, law_id: str, label: str | None, defect: str, judgment_call: bool = False,
               scope: dict | None = None) -> Scored:
    """A v2 recording whose label's scoring interval cannot be used (`defect`): not evaluated, never a
    match; `label_unverified` when it is labelled, `unlabelled` otherwise."""
    return Scored(recording_id, law_id, label, None, "unlabelled" if label is None else "label_unverified", {},
                  f"label not verified under contract v2: {defect}", None, judgment_call, [],
                  {**(scope or {}), "defect": defect})


def library_actionable(s: Scored) -> bool:
    """A plain-labelled unknown recording with a blocker whose evidence points at the library."""
    return (s.status == "unknown" and s.label is not None and not s.judgment_call
            and any(b["handling"] == "library" for b in s.blockers))


def summary(scored: Iterable[Scored], expected: Iterable[str] | None = None) -> dict:
    """Counts per status, and agreement over the labelled recordings, judgment calls apart. With
    `expected` (every recording key of the fixed set), a missing or unexpected key is refused."""
    s = list(scored)
    if len({x.scope is None for x in s}) > 1:
        raise ValueError("whole-recording and scoring-interval scores are never joined in one summary")
    statuses = STATUSES_V2 if any(x.scope is not None for x in s) else STATUSES
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
    return {"recordings": len(s), "counts": {k: counts.get(k, 0) for k in statuses},
            "blockers": {"handling": {h: sum(any(b["handling"] == h for b in x.blockers) for x in unknown) for h in HANDLINGS},
                         "class": dict(Counter(c for x in unknown for c in {b["class"] for b in x.blockers}))},
            "library_actionable": sum(library_actionable(x) for x in s),
            "unlabelled_failures": sum(x.label is None and x.failure is not None for x in s),
            "partial": sum(x.partial for x in s),
            "found_violation": sum(x.found_violation is not None for x in s),
            **figures([x for x in labelled if not x.judgment_call]),
            "judgment_call": figures([x for x in labelled if x.judgment_call])}
