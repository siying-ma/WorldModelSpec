"""The label check: a law's rules run on the training recordings of that law, their verdicts joined
and compared with the labels, and the evidence for the planner rendered. Deterministic, no model.

Reason: in training mode it is the one semantic signal; it trusts the verdict Lean computes on a
trace and compares it with the recording's label under the label contract (`recorded.labels`).

Per recording, the monitor runs each of the law's expected rules in its own process, under the
budget per rule and recording (a deadline and a memory cap), on the recording's trace with its
source's manifest (one manifest per scene-graph generator or adapter version, never one per
recording); the results are joined and scored by `recorded.scoring` (only the groundings whose
subject binder is the ego are joined). Explain reads the same trace and manifest.

The expected rules of a law are the nodes of its final plan (the run's ledger), whether or not each
was accepted: a node that was not accepted, or is fenced, is not run, and every recording of the law
reports the rule set incomplete, with each such node's state.

The eligible set of a law is fixed by the labels, never by a status: its recordings with a plain
label (an explicit verdict that is not a judgment call). A law's outcome over that set:
- `incomplete`: some expected rule is not available (the law's plan was not completed);
- `aligned`: the set is not empty and every recording in it is a match;
- `mismatch`: some recording is a mismatch: the law goes to repair with the evidence;
- `failed`: no mismatch, but some recording passed a rule's deadline or memory cap, crashed,
  reported an incomplete rule set or no single subject: a performance or infrastructure
  question, never a semantic repair; an unknown recording the library could decide is still
  counted in the summary (`library_actionable`), never hidden by the failure;
- `undecided`: none of the above, and some recording is unknown with a blocker whose evidence points
  at the library, or a truncated-window blocker with an eligible window diagnosis
  (`scoring.library_actionable`): the law goes to a coverage repair, whose goal is that more
  recordings are decided; the recording's other blockers stay what they are. An unknown turned into
  a mismatch is that goal met, and the law then goes to a semantic repair;
- `unverified`: none of the above with some recording not a match (unknown, whatever its blockers,
  no_rule), or an empty set. The matches it has are kept and reported with the coverage; a gate
  that passed keeps its product, but the law is not reported aligned.
Judgment-call labels (a verdict that turns on a parameter the pipeline chooses) never decide the
outcome and never enter the evidence; they are listed apart for the operator's parameter review.
A law whose rules rest on an approved abstraction (`scoring`, Coverage) is checked and routed like any
other, but its scope is `partial_coverage`, with the abstractions named: its agreement is never
reported as full statutory alignment. Any other law's scope is `full`: complete within the approved
task scope (scope readings are disclosed in the rule's reading); not a word-by-word verification of
every qualifier of the statute.

A label judges the whole recording (`recorded.labels`). The monitor runs on the whole trace with
each grounding's reason-carrying segments (`--segments`), which the window diagnosis reads.

The evidence for an eligible recording that does not match is the Explain report of each of the
law's rules for the groundings that judge the ego, with each grounding's whole binding, at the
observations `--scan` chooses. The groundings whose episode verdict is the rule's joined verdict
decide it and come first, in report order, then the others; at most `Limits.explain_groundings`
are explained per rule, and a cut is stated with how many deciding groundings it left out. A report is pruned at structural boundaries to stay valid JSON, with every pruned list
marked; the whole report is kept as a file when an artifact folder is given. An Explain that
fails or passes its own deadline is a diagnostic failure and changes nothing in the score.

Explain also reports, per grounding, the truncated windows its verdict carries at the unknown
observations of the recording (`windows`). That section is taken from the whole report before
anything is pruned and kept beside it (`Evidence.windows`), with the digests of the Explain source
and the reading it was made on; the window diagnosis of an unknown recording
(`scoring.diagnose_windows`) is decided on it, and rendered as its own block of facts: the located
windows, the coverage, the eligibility, a statement when the coverage is partial and, where a window
is eligible, that a window should be anchored to the event and how the limitation is left undecided.
No new Explain run is made for it.
"""
from __future__ import annotations

import json
import resource
import subprocess
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from dataclasses import asdict, dataclass, field
from pathlib import Path

from recorded import dataset as dataset_mod
from recorded import labels, scoring, source_check

OUTCOMES = ("aligned", "mismatch", "incomplete", "failed", "undecided", "unverified")
FAILED = ("deadline", "crash", "incomplete", "contract_failed")
#: How many recordings the source report reads at once (each streams its trace in little memory).
SOURCE_CHECK_JOBS = 8


@dataclass(frozen=True)
class Limits:
    deadline_s: float = 900          # per rule and recording
    memory_gb: float = 24            # per rule and recording
    explain_s: float = 300           # per Explain call
    explain_groundings: int = 3      # groundings explained per rule and recording
    evidence_chars: int = 20000      # a report's rendered size before it is pruned
    jobs: int = 4


@dataclass
class Evidence:
    recording_id: str
    rule: str
    binding: dict
    ok: bool
    report: dict | None = None      # Explain's JSON (`--scan --json`), possibly pruned
    pruned: bool = False
    artifact: str = ""              # the whole report, when kept
    error: str = ""
    windows: dict | None = None     # the report's truncated windows, whole (taken before pruning)
    inputs: dict = field(default_factory=dict)     # the digests of the Explain source and reading it was made on


@dataclass
class LawCheck:
    law_id: str
    rules: list[str]
    outcome: str
    scored: list[scoring.Scored] = field(default_factory=list)
    evidence: list[Evidence] = field(default_factory=list)
    data_version: str = ""
    notes: list[str] = field(default_factory=list)
    versions: dict = field(default_factory=dict)   # what the check is bound to, when it ran on a candidate library
    source_check: dict = field(default_factory=dict)   # the source report of its recordings (`recorded.source_check`): reported, never scored

    @property
    def summary(self) -> dict:
        return scoring.summary(self.scored)

    @property
    def coverage(self) -> dict:
        eligible = [s for s in self.scored if s.label is not None and not s.judgment_call]
        return {"eligible": len(eligible), "matched": sum(s.status == "match" for s in eligible)}

    @property
    def abstractions(self) -> list[str]:
        """The approved abstractions the law's verdicts rest on, over every recording."""
        return sorted({a for s in self.scored for a in s.abstractions})

    @property
    def sampled_duration(self) -> bool:
        """Whether the law's verdicts rest, on some recording, on a duration read from the samples."""
        return any(s.sampled_duration for s in self.scored)

    @property
    def scope(self) -> str:
        """`partial_coverage` where the law's verdicts rest on an approved abstraction, else `full`:
        complete within the approved task scope (scope readings are disclosed in the rule's
        reading); not a word-by-word verification of every qualifier of the statute."""
        return "partial_coverage" if self.abstractions else "full"

    def to_dict(self) -> dict:
        return {"law_id": self.law_id, "rules": self.rules, "outcome": self.outcome, "data_version": self.data_version,
                "scope": self.scope, "abstractions": self.abstractions, "sampled_duration": self.sampled_duration,
                "coverage": self.coverage, "summary": self.summary, "notes": self.notes,
                "scored": [s.to_dict() for s in self.scored], "evidence": [_evidence_dict(e) for e in self.evidence],
                **({"versions": self.versions} if self.versions else {}),
                **({"source_check": self.source_check} if self.source_check else {})}


def _evidence_dict(e: Evidence) -> dict:
    """An evidence record; the window section and its digests only where Explain reported one."""
    d = asdict(e)
    if d["windows"] is None:
        d.pop("windows")
        d.pop("inputs")
    return d


class LabelsDeferred(Exception):
    """A training-data entry point (the training context, the label monitor, Explain on a recording)
    was called while this process defers its label checks (`deferred`): a defect of the caller, never
    a check that did not run, so no handler that treats an unrun check as a wait catches it."""


_DEFERRED: list[str] = []


@contextmanager
def deferred(reason: str):
    """For its duration no training recording may be read by this process: every entry point that
    would read one raises `LabelsDeferred` naming `reason`."""
    _DEFERRED.append(reason)
    try:
        yield
    finally:
        _DEFERRED.remove(reason)


def refuse_if_deferred(what: str) -> None:
    if _DEFERRED:
        raise LabelsDeferred(f"{what} was called while label checks are deferred ({_DEFERRED[-1]}): no training recording is read here")


def _limit(memory_gb: float):
    def set_limit():
        cap = int(memory_gb * (1 << 30))
        resource.setrlimit(resource.RLIMIT_AS, (cap, cap))
    return set_limit


def incomplete_sets(ledger: dict[str, dict], accepted: dict[str, dict]) -> list[str]:
    """The rule-set ids (`#requiredBy:<conduct>`, `#lawful:…`) an accepted record reads whose set may
    lack a rule: some law of the run has a node that is not accepted, or no node at all, and nothing
    accepted says what that law's rules would be. The monitor then never counts such a set as
    deciding: a `requiredBy` there is never false and a `lawful` never true, unknown instead. An
    operator with no composition id (`rule_set_id`) raises `ValueError`, never a set left out."""
    from ..checks.gate import rule_set_id
    read = set()
    for ident, rec in accepted.items():
        for x in [] if rec.get("fenced") else [x for x in rec.get("rule_sets", []) or [] if isinstance(x, dict)]:
            try:
                read.add(rule_set_id(x))
            except ValueError as e:
                raise ValueError(f"accepted record `{ident}`: {e}") from None
    read = sorted(read)
    missing = any(not e.get("nodes") or any(n not in accepted or accepted[n].get("fenced") for n in e.get("nodes") or [])
                  for e in ledger.values())
    return read if missing else []


def run_incomplete(run) -> list[str]:
    """`incomplete_sets` of a run: its ledger (`state.json`) and its accepted records."""
    f = Path(run.dir) / "state.json"
    ledger = {e["law"]: e for e in (json.loads(f.read_text(encoding="utf-8")).get("ledger") or [])} if f.exists() else {}
    return incomplete_sets(ledger, run.all_nodes())


def run_rule(monitor: Path, files: dict[str, Path], rule: str, reading: Path,
             lim: Limits, incomplete: list[str] | tuple = ()) -> tuple[list[str] | None, str | None]:
    """The monitor's JSON lines for one rule on one recording, with each grounding's reason-carrying
    segments, or its failure (`deadline` for the time or memory budget, `crash` otherwise). The
    rule-set ids in `incomplete` are passed to the monitor as sets that may lack a rule."""
    refuse_if_deferred("the label monitor")
    cmd = [str(monitor), "--manifest", str(files["manifest"]), "--reading", str(reading), "--rules", rule,
           *(["--incomplete", ",".join(incomplete)] if incomplete else []),
           "--json", "--segments", str(files["trace"])]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=lim.deadline_s, preexec_fn=_limit(lim.memory_gb))
    except subprocess.TimeoutExpired:
        return None, "deadline"
    if p.returncode != 0:
        return None, "deadline" if "out of memory" in p.stderr.lower() or p.returncode in (-9, 137) else "crash"
    return p.stdout.splitlines(), None


def merge_reports(per_rule: dict[str, list[str]]) -> list[str]:
    """One report from the per-rule runs: every rule and grounding line, and one subject line whose
    binders are the union. Runs that name different subjects keep them all, so the scoring sees no
    single subject (a contract failure) rather than a chosen one."""
    out, egos, binders = [], [], {}
    for lines in per_rule.values():
        for line in lines:
            if not line.strip():
                continue
            d = json.loads(line)
            if d.get("kind") == "subject":
                egos.extend(e for e in d.get("ego", []) if e not in egos)
                binders.update(d.get("binders", {}))
            elif d.get("kind") in ("rule", "grounding", "segments"):
                out.append(line)
    out.append(json.dumps({"kind": "subject", "ego": egos, "binders": binders}))
    return out


def prune(obj, budget: int, items: int = 3):
    """`obj` with every list cut to its first `items` entries (a cut list ends with
    `{"omitted": n}`), deepest first, until its JSON is within `budget` characters or nothing is
    left to cut. Returns the pruned value and whether anything was cut."""
    def cut(x, depth):
        if isinstance(x, dict):
            return {k: cut(v, depth + 1) for k, v in x.items()}
        if isinstance(x, list):
            kept = [cut(v, depth + 1) for v in x[:items]]
            return kept + ([{"omitted": len(x) - items}] if len(x) > items else [])
        return x
    if len(json.dumps(obj, ensure_ascii=False)) <= budget:
        return obj, False
    out = cut(obj, 0)
    if len(json.dumps(out, ensure_ascii=False)) > budget and isinstance(out, dict):
        out = {k: v for k, v in out.items() if not isinstance(v, (list, dict))} | {"omitted": "every nested part: see the kept report"}
    return out, True


def explain_inputs(explain: Path, reading: Path) -> dict:
    """The digests of what an Explain report depends on beside the library it was built in: its own
    source (`Explain.lean` of the library whose build holds the binary) and the reading."""
    lib = explain.resolve().parents[3] if len(explain.resolve().parents) > 3 else explain.parent
    return {"explain": _file_sha(lib / "Explain.lean"), "reading": _file_sha(reading)}


def reading_params(reading: Path) -> dict:
    """The reading's parameters, name → (Core unit tag, value in that unit), as the decoder scales them."""
    from fractions import Fraction
    from ..model import units
    try:
        rows = json.loads(reading.read_text(encoding="utf-8")).get("params", [])
    except (OSError, ValueError, AttributeError):
        return {}
    out = {}
    for p in rows if isinstance(rows, list) else []:
        try:
            core, value = units.to_core(p["value"], p["unit"])
            out[p["name"]] = (units.json_tag(core), Fraction(value))
        except (KeyError, TypeError, ValueError):
            continue
    return out


def run_explain(explain: Path, files: dict[str, Path], rule: str, binding: dict, reading: Path, lim: Limits,
                artifacts: Path | None = None) -> Evidence:
    """Explain's report of one grounding at the observations `--scan` chooses on the whole trace; the
    report's truncated windows are taken whole, before the report is pruned."""
    refuse_if_deferred("Explain on a recording")
    inputs = explain_inputs(explain, reading)
    cmd = [str(explain), "--manifest", str(files["manifest"]), "--reading", str(reading), "--rule", rule]
    for name, track in binding.items():
        cmd += ["--bind", f"{name}={track}"]
    cmd += ["--scan", "--json", str(files["trace"])]
    rid = files["trace"].parent.name
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=lim.explain_s, preexec_fn=_limit(lim.memory_gb))
    except subprocess.TimeoutExpired:
        return Evidence(rid, rule, binding, False, error=f"explain did not finish within {lim.explain_s:.0f} s")
    if p.returncode != 0:
        return Evidence(rid, rule, binding, False, error=p.stderr.strip()[-400:])
    try:
        report = json.loads(p.stdout)
    except json.JSONDecodeError as e:
        return Evidence(rid, rule, binding, False, error=f"explain output is not JSON: {e}")
    windows = None
    for g in report.get("groundings", []) if isinstance(report, dict) else []:
        w = g.pop("windows", None) if isinstance(g, dict) else None
        if w is not None and g.get("binding") == binding:
            windows = w
    kept = ""
    if artifacts is not None:
        artifacts.mkdir(parents=True, exist_ok=True)
        name = f"{rid}__{rule}__{'_'.join(f'{k}{v}' for k, v in binding.items())}.json"
        (artifacts / name).write_text(p.stdout, encoding="utf-8")
        kept = str(artifacts / name)
    small, pruned = prune(report, lim.evidence_chars)
    return Evidence(rid, rule, binding, True, small, pruned, kept, windows=windows, inputs=inputs)


def outcome_of(scored: list[scoring.Scored], complete: bool = True) -> str:
    eligible = [s for s in scored if s.label is not None and not s.judgment_call]
    if not complete:
        return "incomplete"
    if any(s.status == "mismatch" for s in eligible):
        return "mismatch"
    if any(s.status in FAILED for s in eligible):
        return "failed"
    if any(scoring.library_actionable(s) for s in eligible):
        return "undecided"
    return "aligned" if eligible and all(s.status == "match" for s in eligible) else "unverified"


def check_law(law_id: str, rules: list[str], law_of: dict[str, str], ds: dataset_mod.Dataset, monitor: Path,
              explain: Path | None, reading: Path, lim: Limits = Limits(), artifacts: Path | None = None,
              unavailable: dict[str, str] | None = None, incomplete: list[str] | tuple = (),
              permissions: set[str] | frozenset = frozenset()) -> LawCheck:
    """Run the law's expected `rules` (every rule `law_of` maps to the law) on every training
    recording of the law, score each, and explain each eligible recording that does not match.
    `unavailable` maps an expected rule that is not run to its state (not accepted, fenced). A rule
    that fails on a recording is not run again; the rules that finished there keep their results."""
    refuse_if_deferred("the label check of a law")
    expected = sorted(r for r, law in law_of.items() if law == law_id)
    if sorted(rules) != expected:
        raise ValueError(f"{law_id}: the rules given {sorted(rules)} are not the law's expected rules {expected}")
    unavailable = {r: s for r, s in (unavailable or {}).items() if r in expected}
    runnable = [r for r in expected if r not in unavailable and r not in permissions]   # a permission is never violated: outside the check
    rows = [r for r in ds.rows if r["law_id"] == law_id]
    notes: list[str] = [f"{r}: not run ({s})" for r, s in sorted(unavailable.items())]
    notes += [f"{r}: a permission, outside the label check" for r in expected if r in permissions]
    if incomplete:
        notes.append(f"rule sets the run declares incomplete (never deciding where a missing rule could): {', '.join(incomplete)}")
    if not expected:
        notes.append("the law's final plan has no node: nothing was generated for it")

    def one(row: dict):
        rid = row["recording_id"]
        files = ds.files(rid)
        lab = ds.label(rid)
        per_rule, failures = {}, {}
        for r in runnable:
            lines, failure = run_rule(monitor, files, r, reading, lim, incomplete)
            if failure:
                failures[r] = failure
            else:
                per_rule[r] = lines
        results = scoring.rule_results(merge_reports(per_rule)) if per_rule else {}
        declared = json.loads(Path(files["manifest"]).read_text(encoding="utf-8")).get("atoms", {})
        s = scoring.score(rid, law_id, lab.verdict, results, law_of, judgment_call=lab.judgment_call,
                          declared=declared, failed=failures)
        if failures:
            s.note = "; ".join(f"{r}: {f}" for r, f in sorted(failures.items()))
        ev: list[Evidence] = []
        if explain is not None and lab.verdict is not None and not lab.judgment_call and s.status != "match" \
                and s.failure is None and results:
            for r in expected:
                x = results.get(r)
                if not x or x.support == "unsupported":
                    continue
                deciding = [g for g in x.judged if g.verdict == x.verdict]
                ordered = deciding + [g for g in x.judged if g.verdict != x.verdict]
                for g in ordered[:lim.explain_groundings]:
                    ev.append(run_explain(explain, files, r, g.binding, reading, lim, artifacts))
                if len(ordered) > lim.explain_groundings:
                    left = max(0, len(deciding) - lim.explain_groundings)
                    notes.append(f"{rid[:12]} {r}: {len(ordered) - lim.explain_groundings} of {len(ordered)} groundings "
                                 f"judging the ego not explained ({left} of them deciding the verdict {x.verdict})")
                if not x.judged:
                    notes.append(f"{rid[:12]} {r}: no grounding binds the ego, so nothing to explain "
                                 "(the rule never engaged the subject)")
        if explain is not None:
            now = explain_inputs(explain, reading)
            scoring.diagnose_windows(s, [{"rule": e.rule, "binding": e.binding, "ok": e.ok, "windows": e.windows,
                                          "current": e.inputs == now, "error": e.error} for e in ev], reading_params(reading))
        return s, ev

    with ThreadPoolExecutor(max(1, lim.jobs)) as pool:
        out = list(pool.map(one, rows))
    scored = [s for s, _ in out]
    complete = bool(expected) and not unavailable
    return LawCheck(law_id, expected, outcome_of(scored, complete), scored, [e for _, ev in out for e in ev], ds.data_version, notes)


def goal_for(outcome: str) -> str:
    """The repair goal of a law's outcome: a coverage repair for an undecided law, else a semantic one."""
    return "coverage" if outcome == "undecided" else "labelled semantic"


def render_evidence(chk: LawCheck, repair_goal: str | None = None) -> str:
    """The `## Label mismatches` block for the planner: the contract, the goal, the fixed comparison
    set, and each eligible recording that does not match with its derivations. No trace, video or
    mapping, and no judgment-call recording."""
    eligible = [s for s in chk.scored if s.label is not None and not s.judgment_call]
    repair_goal = repair_goal or goal_for(chk.outcome)
    c = labels.CONTRACT
    out = ["## Label mismatches", "",
           f"Law: {chk.law_id}. Rules checked together: {', '.join(chk.rules)}. Repair goal: {repair_goal}."
           + (f" The rules rest on the approved abstraction(s) {', '.join(chk.abstractions)}: their verdicts are partial "
              "coverage, compared with the labels like any other." if chk.abstractions else "")
           + (" The rules read a duration from the trace's samples (`durationWithin`): their verdicts judge the time the "
              "samples show, not a proof of the continuous state between frames; this is not partial coverage, and these "
              "recordings count in the comparison like any other." if chk.sampled_duration else ""),
           f"Label contract: a label judges the {c['subject']} (the trace's subject) over the {c['scope']}; "
           "violated = the situation was violated at least once, compliant = every occurrence complied, "
           "not_applicable = the situation never arose for the subject.",
           f"Fixed comparison set: {len(eligible)} labelled recording(s) of this law (data version {chk.data_version[:12]}); "
           f"{chk.coverage['matched']} match. Every match must stay a match and no decided recording may become undecided.", ""]
    counts = {k: sum(s.status == k for s in eligible) for k in scoring.STATUSES if any(s.status == k for s in eligible)}
    out.append("Statuses: " + ", ".join(f"{k} {v}" for k, v in counts.items()))
    for s in eligible:
        if s.status == "match":
            continue
        out += ["", f"### Recording {s.recording_id[:12]}: label {s.label}, the law's verdict {s.verdict}, status {s.status}"]
        if s.note:
            out.append(s.note)
        if s.partial:
            out.append(f"Partial: {', '.join(f['node'] for f in s.failed)} did not finish, so the law has no verdict here "
                       "and the recording is not compared with its label; the rules below are those that finished.")
        if s.found_violation:
            out.append(f"Found violation, not a verdict: {', '.join(s.found_violation['nodes'])} proved a violation; "
                       f"the recording stays {s.status}.")
        for r, x in sorted(s.rules.items()):
            out.append(f"- {r}: verdict {x.get('verdict')}, support {x.get('support')}"
                       + (f", absent {', '.join(x.get('absent', []))}" if x.get("absent") else ""))
        if s.blockers:
            out.append("Why it is unknown (each reason, its kind and who its evidence points at: `library` is a "
                       "repair's to remove; `data`, `time_contract`, `harness` and `aggregate` are not removed by "
                       "changing what the rule means; `investigate` is shown to be neither side's):")
            out += [f"  - {b['rule']}: `{b['reason'] or '(no reason)'}` — {b['class']}, {b['handling']}"
                    + (f"; {b['evidence']}" if b.get("evidence") else "")
                    + (f"; {b['observations']} observation(s)" if b.get("observations") else "")
                    for b in s.blockers]
        if s.windows:
            out += window_block(s)
        for e in chk.evidence:
            if e.recording_id != s.recording_id:
                continue
            bind = ", ".join(f"{k}={v}" for k, v in e.binding.items())
            if e.ok:
                head = f"Derivation of {e.rule} for {bind} (Explain, exact values"
                head += "; lists cut where marked `omitted`, the whole report kept by the harness)" if e.pruned else ")"
                out += [head + ":", "```json", json.dumps(e.report, ensure_ascii=False), "```"]
            else:
                out.append(f"Derivation of {e.rule} for {bind} unavailable: {e.error}")
    for n in chk.notes:
        out.append(f"Note: {n}")
    return "\n".join(out) + "\n"


def _q(x) -> str:
    from fractions import Fraction
    if not isinstance(x, dict) or not x.get("den"):
        return "?"
    q = Fraction(x["num"], x["den"])
    return str(q.numerator) if q.denominator == 1 else f"{float(q):.3f}"


def window_block(s: scoring.Scored) -> list[str]:
    """The window evidence of a recording, as facts: each located window (its rule, source, call
    chain, binding, operator, direction and measure, its length as written and as substituted with the
    reading's value, the requested and observed window, where it was met and evaluated), whether it is
    eligible for a diagnosis and why not, the coverage, a statement when the coverage is partial, and,
    where a window is eligible, that a window should be anchored to the event and the request-only route
    for leaving the limitation undecided."""
    w = s.windows or {}
    out = ["Window diagnosis (the truncated windows this verdict carries in the recording, located by "
           "Explain; the attribution above is unchanged, and an eligible window authorizes a diagnosis only):"]
    for p in w.get("pieces", []):
        src = p.get("source") or {}
        chain = " → ".join(f"{c['concept']} (called at {c['owner']} {c['path']}, tag {c['tag']}"
                           + (f"; params {', '.join(f'{k}={v}' for k, v in c.get('params', {}).items())}" if c.get("params") else "")
                           + (f"; args {', '.join(f'{k}={v}' for k, v in c.get('args', {}).items())}" if c.get("args") else "") + ")"
                           for c in p.get("calls", []))
        ln, ex, sc, ev = p.get("length") or {}, p.get("example") or {}, p.get("scoring") or {}, p.get("evaluated") or {}
        line = (f"  - {p.get('rule')}: `{p.get('op')}`" + (f" ({p.get('direction')}, {p.get('measure')})" if p.get("measure") else "")
                + f" at {src.get('owner')} {src.get('path')} [expanded {p.get('expanded_path')}]"
                + (f", through {chain}" if chain else "")
                + f"; binding {', '.join(f'{k}={v}' for k, v in (p.get('binding') or {}).items())}")
        if ln.get("written") is not None:
            line += f"; length written `{ln.get('written')}`, after substitution `{ln.get('substituted')}`"
            if ln.get("param"):
                line += f" = {_q(ln.get('value'))} {ln.get('unit')}"
        rq, ob = ex.get("requested"), ex.get("observed")
        if rq and ob:
            line += (f"; requested [{_q(rq.get('from'))}, {_q(rq.get('to'))}] {rq.get('unit')}, observed "
                     f"[{_q(ob.get('from'))}, {_q(ob.get('to'))}] {rq.get('unit')}, {'covered' if ob.get('covered') else 'not covered'}")
        line += (f"; met at {sc.get('instants')} unknown observation(s), scoring t={sc.get('first_ms')}…{sc.get('last_ms')} ms, "
                 f"evaluated at t={ev.get('first_ms')}…{ev.get('last_ms')} ms")
        line += "; eligible for diagnosis" if p.get("eligible") else f"; not eligible: {p.get('not_eligible')}"
        out.append(line)
    cov = w.get("coverage") or {}
    out.append(f"  Coverage: of {cov.get('unknown_observations', 0)} unknown observation(s) with a truncated window, "
               f"{cov.get('with_located_source', 0)} have at least one located source and the cause search was complete at "
               f"{cov.get('search_complete', 0)}" + (f"; {cov['groundings_not_explained']} unknown grounding(s) not explained"
                                                     if cov.get("groundings_not_explained") else "") + ".")
    out += [f"  Note: {n}" for n in w.get("notes", [])]
    if w.get("partial"):
        out.append("  Partial: this evidence does not cover every unknown observation of the recording; it permits a diagnosis "
                   "of the located windows only.")
    eligible = [b for b in s.blockers if (b.get("window_diagnosis") or {}).get("eligible")]
    out.append("  Window diagnosis eligible for: " + (", ".join(f"{b['rule']} `{b['reason']}`" for b in eligible) or "none") + ".")
    if eligible:
        out.append("  A window should be anchored to the event itself, for example by looking back to the start of the "
                   "action, not depend on history from before the recording began.")
        out.append("  Where the justified meaning still needs context the recordings do not give, the window is left as it is "
                   "and the limitation is reported as a change request alone (`change_request.json` with type `coverage`, "
                   "object `parameter`, target the parameter), with no record and no diff.")
    return out


def judgment_table(chk: LawCheck) -> list[dict]:
    """The judgment-call recordings of the law, beside the verdict the current reading gives: a
    status table for the operator. It is no label: a judgment-call label is confirmed by a
    scenario standard independent of the rules, never from this table."""
    return [{"recording_id": s.recording_id, "law_id": s.law_id, "recorded_label": s.label, "verdict": s.verdict,
             "status": s.status} for s in chk.scored if s.judgment_call]


# ---------------------------------------------------------------------------------------------
# Training inside the loop (`label_repair`): the comparison set fixed at the run's start, the check
# of a law on a candidate library, and the non-regression check of a repair transaction
# ---------------------------------------------------------------------------------------------
#: What a repair may set out to improve, each with its own measure of progress (`progress`).
REPAIR_GOALS = ("labelled semantic", "sweep", "performance", "coverage")
#: The statuses that decide a plain label: agreement or disagreement.
DECIDED = ("match", "mismatch")
#: The versions a run's comparison set is bound to; a launch on other values is refused.
SET_VERSIONS = ("data_version", "label_contract", "scoring")


def _digest(x) -> str:
    import hashlib
    return hashlib.sha256(json.dumps(x, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def contract_version() -> str:
    return _digest(labels.CONTRACT)


def scoring_version() -> str:
    """The digest of the code that turns monitor reports into statuses and outcomes: the verdict joins
    and statuses, the label reading, this module, and the Explain source whose window report decides
    a window diagnosis and so a route."""
    import hashlib
    from ..store import paths
    h = hashlib.sha256()
    for f in (Path(scoring.__file__), Path(labels.__file__), Path(__file__), paths.LIBRARY / "Explain.lean"):
        h.update(f.name.encode()); h.update(f.read_bytes() if f.is_file() else b"(missing)")
    return h.hexdigest()


def _file_sha(p: Path) -> str | None:
    import hashlib
    return hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None


def bound_limits(lim: Limits) -> dict:
    """The execution limits a score depends on (the scheduling's concurrency is not one)."""
    return {k: v for k, v in asdict(lim).items() if k != "jobs"}


def comparison_set(ds: dataset_mod.Dataset, law_ids: set[str], lim: Limits | None = None) -> dict:
    """What a run's label checks are fixed on, read from the files themselves: every recording of the
    dataset for each of `law_ids`, and among them the eligible ones (a plain label: an explicit verdict
    that is no judgment call) and the judgment calls; per recording its expected verdict, whether it is
    a judgment call, the digest of its label fields in the index, of its trace and of its source's
    manifest; the digest of the index, the dataset's split and the library's active split; the data
    version, the label contract, the scoring version and the execution limits. A trace or manifest
    whose digest differs from the one the dataset states is refused (`ValueError`)."""
    from ..store import paths
    laws: dict[str, dict] = {}
    cases: dict[str, dict] = {}
    bad = []
    for row in ds.rows:
        if row["law_id"] not in law_ids:
            continue
        rid, files = row["recording_id"], ds.files(row["recording_id"])
        lab = ds.label(rid)
        e = laws.setdefault(row["law_id"], {"recordings": [], "eligible": [], "judgment_calls": []})
        e["recordings"].append(rid)
        if lab.verdict is not None:
            e["judgment_calls" if lab.judgment_call else "eligible"].append(rid)
        c = {"law": row["law_id"], "verdict": lab.verdict, "judgment_call": lab.judgment_call,
             "label": _digest([lab.recorded_label, lab.verdict, lab.judgment_call]),
             "trace": _file_sha(files["trace"]), "manifest": _file_sha(files["manifest"])}
        for k, want in ds.expected_sha256(rid).items():
            if want != c[k]:
                bad.append(f"{rid}: its {k} is not the one the dataset states")
        cases[rid] = c
    if bad:
        raise ValueError("the dataset's files differ from its index: " + "; ".join(bad[:6]))
    active = paths.LIBRARY / "splits" / "ACTIVE"
    return {"data_version": ds.data_version, "dataset": str(ds.path), "label_contract": contract_version(),
            "scoring": scoring_version(), "index": _file_sha(ds.path / "INDEX.csv"), "split": ds.meta.get("split"),
            "library_split": active.read_text(encoding="utf-8").strip() if active.exists() else None,
            "limits": bound_limits(lim or Limits()), "laws": {k: laws[k] for k in sorted(laws)}, "cases": cases}


def jobs_for(memory_gb: float) -> int:
    """How many monitor or Explain processes run at once: as many as the memory available holds at
    the per-process cap, at least one, at most one per processor."""
    import os
    try:
        avail = next(int(l.split()[1]) for l in Path("/proc/meminfo").read_text().splitlines() if l.startswith("MemAvailable:")) / (1 << 20)
    except (OSError, StopIteration, ValueError):
        return 1
    return max(1, min(os.cpu_count() or 1, int(avail // max(memory_gb, 1e-9))))


@dataclass
class Training:
    """What an in-loop label check runs with: the dataset, the run's fixed comparison set, the budgets,
    and the files' sizes and times as this launch hashed them (`check_inputs`)."""
    dataset: dataset_mod.Dataset
    fixed: dict
    limits: Limits = field(default_factory=Limits)
    seen: dict = field(default_factory=dict)
    sources: dict = field(default_factory=dict)     # recording id → its source report, bound to the fixed set's files

    def source_summary(self, law: str) -> dict:
        """The source report of the law's recordings in the fixed set (`recorded.source_check.summary`)."""
        return source_check.summary({r: self.sources.get(r) for r in self.fixed["laws"].get(law, {}).get("recordings", [])})

    def versions(self) -> dict:
        """The label versions a candidate is bound to."""
        return {"data": self.fixed["data_version"], "label_contract": self.fixed["label_contract"], "scoring": self.fixed["scoring"],
                "limits": _digest(self.fixed["limits"])}

    def bind(self, txn) -> None:
        """Bind a candidate to the versions its label checks rest on; a candidate bound to others is refused."""
        want = self.versions()
        clash = {k: v for k, v in want.items() if txn.bound.get(k) not in (None, v)}
        if clash:
            raise ValueError(f"candidate {txn.id} is bound to other label versions: {sorted(clash)}")
        txn.bind(**want)

    def check_inputs(self, rids: list[str]) -> None:
        """Before recordings are consumed: the index that holds their labels is the one fixed (its
        digest, read again: small) and each trace and source manifest is the file this launch hashed
        (its size and modification time unchanged); else `ValueError`, nothing is scored."""
        if _file_sha(self.dataset.path / "INDEX.csv") != self.fixed["index"]:
            raise ValueError("the dataset's index (its labels) changed since the run fixed its comparison set")
        for rid in rids:
            files = self.dataset.files(rid)
            for k in ("trace", "manifest"):
                st = files[k].stat() if files[k].exists() else None
                if (st and (st.st_size, st.st_mtime_ns)) != self.seen.get((rid, k)):
                    raise ValueError(f"{rid}: its {k} changed since this launch checked it")


def training_context(run_dir: Path, law_ids: list[str], dataset_path: Path, limits: Limits | None = None) -> Training:
    """The comparison set fixed when a run starts (`comparison_set.json` in the run's directory),
    read from the files' content at every launch: the first launch writes it; a later launch whose
    labels, traces, manifests, index, splits, data version, label contract, scoring version or
    execution limits differ is refused before anything runs, and nothing of the run is rewritten.
    The concurrency of the monitor and Explain is set from the memory available (`jobs_for`).
    Each recording of the set gets its source report once (`source_check.json` in the run's
    directory, bound to the trace and manifest digests the set fixes): a report, which no status,
    outcome or route reads."""
    refuse_if_deferred("the training context")
    from ..store import jsonl
    import dataclasses
    lim = limits or Limits()
    lim = dataclasses.replace(lim, jobs=min(lim.jobs, jobs_for(lim.memory_gb)))
    ds = dataset_mod.Dataset(dataset_path)
    try:
        now = comparison_set(ds, set(law_ids), lim)
    except ValueError as e:
        raise SystemExit(f"[loop] {e}")
    f = run_dir / "comparison_set.json"
    was = jsonl.read_json(f, None)
    if was is not None:
        # the dataset's location is recorded, not compared: its content is (data version, index, every case's digests),
        # so a clone that keeps the same dataset elsewhere resumes
        changed = [k for k in sorted(set(was) | set(now)) if k not in ("cases", "laws", "dataset") and was.get(k) != now.get(k)]
        changed += ["laws"] if was.get("laws") != now.get("laws") else []
        changed += [f"recording {r}" for r in sorted(set(was.get("cases", {})) | set(now["cases"]))
                    if was.get("cases", {}).get(r) != now["cases"].get(r)][:6]
        if changed:
            raise SystemExit(f"[loop] the run's comparison set was fixed on other inputs ({', '.join(changed)} changed); "
                             "start a new run id — nothing of this run was rewritten")
    else:
        jsonl.write_atomic(f, json.dumps(now, indent=1, ensure_ascii=False))
    seen = {}
    for rid in now["cases"]:
        for k in ("trace", "manifest"):
            p = ds.files(rid)[k]
            seen[(rid, k)] = (p.stat().st_size, p.stat().st_mtime_ns) if p.exists() else None
    fixed = was or now
    sources = source_check.ensure(run_dir / "source_check.json", ds, sorted(fixed["cases"]),
                                  {r: {"trace": c["trace"], "manifest": c["manifest"]} for r, c in fixed["cases"].items()},
                                  jobs=SOURCE_CHECK_JOBS)
    return Training(ds, fixed, lim, seen, sources)


def build_tools(library: Path) -> tuple[Path, Path]:
    """The monitor and Explain of a library, built there."""
    from ..lean import lean
    code, out = lean.lake_build(library, ["monitor", "explain"])
    if code != 0:
        raise RuntimeError("the monitor or explain does not build:\n" + out[-1500:])
    return library / ".lake/build/bin/monitor", library / ".lake/build/bin/explain"


def check_in_candidate(txn, ctx: Training, laws: dict[str, list[str]], unavailable: dict[str, str], out: Path) -> dict[str, LawCheck]:
    """Each law's label check on a candidate library: its registry and monitor built in the
    candidate, each law's expected rules (`laws`, its final plan) run on its recordings, every check
    bound to the candidate's versions (the label versions bound first) and to the run's fixed set,
    which the scored recordings must equal. Each check and its evidence are written under `out`."""
    refuse_if_deferred("the label check in a candidate")
    from ..lean import index_sync
    from ..store import paths
    ctx.bind(txn)
    checks = {}
    with txn.inside():
        index_sync.write_index()
        monitor, explain = build_tools(paths.LIBRARY)
        versions = txn.versions()
        incomplete = run_incomplete(txn.view)
        for law, rules in sorted(laws.items()):
            ctx.check_inputs(ctx.fixed["laws"].get(law, {}).get("recordings", []))
            chk = check_law(law, sorted(rules), {r: law for r in rules}, ctx.dataset, monitor, explain, txn.view.reading_file,
                            ctx.limits, out / "explain", unavailable, incomplete,
                            {i for i, rec in txn.view.all_nodes().items() if rec.get("permission")})
            fixed = ctx.fixed["laws"].get(law, {"recordings": [], "eligible": []})
            scoring.summary(chk.scored, expected=fixed["recordings"])            # the scored set is the fixed set, or nothing is scored
            got = sorted(s.recording_id for s in chk.scored if s.label is not None and not s.judgment_call)
            if got != sorted(fixed["eligible"]):
                raise ValueError(f"{law}: the eligible recordings differ from the run's fixed set")
            chk.versions = versions
            chk.source_check = ctx.source_summary(law)
            checks[law] = chk
            write_check(chk, out)
    return checks


def write_check(chk: LawCheck, out: Path) -> dict[str, str]:
    """A check's record, its evidence block and its judgment-call table under `out`; returns their paths."""
    paths_ = {"check": out / "laws" / f"{chk.law_id}.json", "evidence": out / "evidence" / f"{chk.law_id}.md",
              "judgment_calls": out / "judgment_calls" / f"{chk.law_id}.json"}
    for p in paths_.values():
        p.parent.mkdir(parents=True, exist_ok=True)
    paths_["check"].write_text(json.dumps(chk.to_dict(), indent=1) + "\n", encoding="utf-8")
    paths_["evidence"].write_text(render_evidence(chk), encoding="utf-8")
    paths_["judgment_calls"].write_text(json.dumps(judgment_table(chk), indent=1) + "\n", encoding="utf-8")
    return {k: str(v) for k, v in paths_.items()}


def eligible_statuses(chk) -> dict[str, str]:
    """Recording id → status over the plain labels of a check (a `LawCheck` or its record)."""
    rows = chk.to_dict()["scored"] if isinstance(chk, LawCheck) else chk.get("scored", [])
    return {s["recording_id"]: s["status"] for s in rows if s.get("label") is not None and not s.get("judgment_call")}


def compare(prev, new, goal: str | None = None) -> dict:
    """A candidate's check of a law against the law's last committed check, over the fixed eligible
    set: no match may be lost and no decided recording may become undecided; with `goal`, the repair's
    own target must be met
    (`progress`). Progress and alignment are reported apart: meeting a goal does not make the law
    aligned, which only `outcome` says."""
    p, n = eligible_statuses(prev) if prev else {}, eligible_statuses(new)
    limits = lambda c: ((c.versions if isinstance(c, LawCheck) else (c or {}).get("versions", {})) or {}).get("limits")
    if goal == "performance" and limits(prev) != limits(new):
        reasons = ["a performance goal compares runs under the same execution limits; these differ"]
        return {"ok": False, "lost": [], "undecided": [], "goal": goal, "goal_met": False, "progress": reasons[0],
                "outcome": new.outcome if isinstance(new, LawCheck) else new.get("outcome"),
                "coverage": {"eligible": len(n), "matched": sum(s == "match" for s in n.values())}, "reasons": reasons}
    lost = sorted(r for r, s in p.items() if s == "match" and n.get(r) != "match")
    undecided = sorted(r for r, s in p.items() if s in DECIDED and n.get(r) not in DECIDED)
    met, why = progress(goal, p, n) if goal else (None, "")
    reasons = [f"match lost: {r}" for r in lost] + [f"decided, now undecided: {r} ({p[r]} → {n.get(r)})" for r in undecided]
    if goal and not met:
        reasons.append(f"repair goal `{goal}` not met: {why}")
    return {"ok": not lost and not undecided and (goal is None or bool(met)), "lost": lost, "undecided": undecided,
            "goal": goal, "goal_met": met, "progress": why, "outcome": new.outcome if isinstance(new, LawCheck) else new.get("outcome"),
            "coverage": {"eligible": len(n), "matched": sum(s == "match" for s in n.values())}, "reasons": reasons}


def progress(goal: str, p: dict[str, str], n: dict[str, str]) -> tuple[bool, str]:
    """Whether a repair met its goal, from the eligible statuses before (`p`) and after (`n`):
    - labelled semantic: a recording that was a mismatch is a match;
    - performance: a recording that passed a deadline or crashed now completes, every decided one unchanged;
    - coverage: more recordings are decided, every decided one unchanged;
    - sweep: measured by the sweep relations, which this check does not carry (never met here)."""
    if goal not in REPAIR_GOALS:
        raise ValueError(f"unknown repair goal {goal!r}")
    kept = all(n.get(r) == s for r, s in p.items() if s in DECIDED)
    if goal == "labelled semantic":
        fixed = sorted(r for r, s in p.items() if s == "mismatch" and n.get(r) == "match")
        return bool(fixed), f"{len(fixed)} mismatch(es) now match" + (f": {', '.join(fixed)}" if fixed else "")
    if goal == "performance":
        done = sorted(r for r, s in p.items() if s in scoring.FAILURES and n.get(r) not in scoring.FAILURES)
        return bool(done) and kept, f"{len(done)} recording(s) now complete" + ("" if kept else "; a decided recording changed")
    if goal == "coverage":
        before, after = sum(s in DECIDED for s in p.values()), sum(s in DECIDED for s in n.values())
        return after > before and kept, f"decided {before} → {after}" + ("" if kept else "; a decided recording changed")
    return False, "a sweep goal is measured on the sweep relations, which are not checked here"


def committed_checks(run_dir: Path, label_states: dict[str, dict]) -> dict[str, dict]:
    """Each routed law's last committed check (its record), what a repair is compared with. A law
    never checked has none; a check its state names that is missing, unreadable, of another law, or
    not the one recorded (its digest) is a data-integrity failure, never an empty baseline."""
    from ..store import jsonl
    out = {}
    for law, st in label_states.items():
        if not st.get("check"):
            continue
        f = run_dir / st["check"]
        if not f.is_file():
            raise jsonl.DataIntegrityError(f, None, f"the committed label check of `{law}` is missing")
        rec = jsonl.read_json(f, None)
        if not isinstance(rec, dict) or rec.get("law_id") != law:
            raise jsonl.DataIntegrityError(f, None, f"not the committed label check of `{law}`")
        if st.get("check_sha") and st["check_sha"] != _file_sha(f):
            raise jsonl.DataIntegrityError(f, None, f"the committed label check of `{law}` is not the one recorded")
        out[law] = rec
    return out


def label_hook(ctx: Training, prior: dict[str, dict], plans: dict[str, list[str]], target: str | None = None,
               goal: str = "labelled semantic"):
    """The candidate transaction's label non-regression check, for every law the change reaches (and
    `target`, the law under repair): each law's rules, the whole of its authoritative final plan
    (`plans`, law → node ids: never inferred from what the candidate still holds, so a withdrawn node
    leaves the law incomplete), checked on the candidate and compared with its last committed check
    (`prior`, law → record, as `committed_checks` reads it);
    it passes only when no match is lost and no decided recording becomes undecided, and for `target`
    only when its `goal` is met. The candidate must be bound to the run's label versions before it is
    verified (`Training.bind`). Each check is kept on the candidate (`label_checks`) for the caller
    to publish with its commit."""
    from .candidate import CheckResult
    from ..model.blueprint import Node

    def hook(txn, aff) -> list:
        laws = sorted(set(aff.laws) | ({target} if target else set()))
        want = {k: v for k, v in ctx.versions().items() if k != "limits"}
        if any(txn.bound.get(k) != v for k, v in want.items()):
            return [CheckResult("label_non_regression", law, "unavailable", ["the candidate is not bound to the run's label versions"])
                    for law in laws]
        missing = [law for law in laws if law not in plans]
        if missing:
            return [CheckResult("label_non_regression", law, "unavailable", ["no authoritative plan of the law was given"]) for law in laws]
        nodes = txn.view.all_nodes()
        rules = {law: list(plans[law]) for law in laws}
        unavailable = {i: ("fenced" if (nodes.get(i) or {}).get("fenced") else "not in the candidate")
                       for law in laws for i in rules[law] if i not in nodes or (nodes.get(i) or {}).get("fenced")}
        try:
            checks = check_in_candidate(txn, ctx, rules, unavailable, txn.area / "label")
        except (RuntimeError, ValueError) as e:
            return [CheckResult("label_non_regression", law, "unavailable", [str(e)[:500]]) for law in laws]
        out = []
        for law in laws:
            cmp = compare(prior.get(law), checks[law], goal if law == target else None)
            txn.label_checks[law] = checks[law]
            details = cmp["reasons"] + [f"outcome {cmp['outcome']} ({cmp['coverage']['matched']}/{cmp['coverage']['eligible']} match; "
                                        "aligned only when every eligible recording matches)"]
            if cmp["goal"]:
                details.append(f"goal `{cmp['goal']}`: {cmp['progress']}")
            if law not in prior:
                details.append("no committed check of this law before: nothing to keep")
            out.append(CheckResult("label_non_regression", law, "pass" if cmp["ok"] else "fail", details))
        return out
    return hook


# ---------------------------------------------------------------------------------------------
# The frozen library a run is scored on
# ---------------------------------------------------------------------------------------------

def _library_files() -> list[Path]:
    from ..store import paths
    files = []
    for root in (paths.RULES_DIR, paths.CONCEPTS_DIR, paths.WITNESS_DIR, paths.CORE, paths.READINGS):
        if root.exists():
            files += sorted(p for p in root.rglob("*") if p.is_file())
    for name in ("TrafficSpec/Index.lean", "TrafficSpecWitness.lean", "TrafficSpec.lean", "Main.lean", "Explain.lean",
                 "lakefile.lean", "lean-toolchain", "lake-manifest.json", "splits/ACTIVE"):
        p = paths.LIBRARY / name
        if p.exists():
            files.append(p)
    return files


def frozen_manifest(run_dir: Path) -> dict:
    """The sha256 of every library file a score depends on (rules, concepts, witnesses, Core, the
    registries, the monitor and explain sources, the build files, the active split, the readings)
    and of the run's own reading and state."""
    import hashlib
    from ..store import paths
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    out = {str(p.relative_to(paths.LIBRARY)): sha(p) for p in _library_files()}
    for name in ("reading.json", "state.json"):
        if (run_dir / name).exists():
            out[f"run/{name}"] = sha(run_dir / name)
    return out


def freeze(run_dir: Path) -> Path:
    """Record the library as the run left it: `frozen/manifest.json` and a copy of every file it
    names under `frozen/snapshot/`, from which the library can be restored."""
    import shutil
    from ..store import paths
    fdir = run_dir / "frozen"
    if fdir.exists():
        shutil.rmtree(fdir)
    (fdir / "snapshot").mkdir(parents=True)
    man = frozen_manifest(run_dir)
    for rel in man:
        src = run_dir / rel[4:] if rel.startswith("run/") else paths.LIBRARY / rel
        dst = fdir / "snapshot" / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    (fdir / "manifest.json").write_text(json.dumps(man, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    return fdir


def drift(run_dir: Path) -> list[str]:
    """How the library and the run's reading and state differ from the run's frozen manifest: a
    missing freeze, and every file added, removed or changed since."""
    f = run_dir / "frozen" / "manifest.json"
    if not f.exists():
        return [f"{run_dir.name} has no frozen library (the loop writes it when it stops)"]
    was, now = json.loads(f.read_text(encoding="utf-8")), frozen_manifest(run_dir)
    return ([f"added since the freeze: {k}" for k in sorted(set(now) - set(was))]
            + [f"removed since the freeze: {k}" for k in sorted(set(was) - set(now))]
            + [f"changed since the freeze: {k}" for k in sorted(k for k in set(was) & set(now) if was[k] != now[k])])
