"""The label repair of one law: a session that answers the law's label mismatches with the whole run
library in reach, its output applied to a candidate transaction, checked there with every law it
reaches, and committed or rolled back.

Reason: in training a mismatch whose cause lies outside one node (a concept several laws call, the
law's cut, a sibling) can only be repaired as one change to the library, kept only when the law
meets its repair goal and no law loses a match.

One law awaiting its label repair gets at most `label_repair_attempts` sessions (a law planned again
inside a repair keeps its count), and the run at most `label_repair_budget` over all laws. A session:
- is shown the law, all its nodes (each revisable), the label evidence its last committed check
  rendered (plain labels only) with the source report of its unknown or mismatched recordings
  (`source_block`, never shown to a plan session), the law's state and repair goal, and the Lean of its rules, their
  witnesses and the concepts they call; it may read, in the candidate, every other record of the run
  it may change, with its law or contract (`records/`), and writes only in its own directory;
- writes any of: `record.jsonl` (node records with `node_id`, concept records, withdrawals with
  `node_id`), `lean.diff` (a unified diff over the files shown), `change_request.json`; an output
  with none of them is refused, a malformed one asked again once.
Its output is applied to the candidate only. A Lean change is applied where the change is local (the
record keeps its segmentation, each span its atoms and concepts, its parameters, and a concept its
interface); a record whose mapping changed, or whose Lean does not pass the gate, is coded by a coding
session in the same candidate. A withdrawal of kind `plan` plans the law again inside the same
candidate (a new cut and every node), then codes it; one of kind `atom` or `operator` files a gap and
blocks the law; one of kind `concept` (a dependency-defect report) waits for the concept
adjudication, with nothing charged, and so does a coder's report no one decided (`review.NOT_JUDGED`),
its candidate unpublished. A change request goes, by its object, to the outer loop's request file
(Core, the ontology, a prompt) or to the operator's queue (a label, a parameter, the corpus, the
adapter, an inherited record), once the candidate is closed.
The candidate is verified with the label hook (the law's repair goal; no law it reaches loses a match
or a decided recording) and the concept review hook; committed, the law is routed again by its new
check (a kept repair is not an aligned law), the law's new route in the same commit; rolled back,
the law stays awaiting its repair, the attempt counted, the candidate kept for diagnosis and what it
failed shown to the law's next repair.
A repair that has not ended (a part that did not run, a report not decided) stays the law's active
repair, in its own directory whatever the iteration: taken up again without a new session while
what it was asked on is unchanged, asked again in a new directory once a commit changed it.
"""
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass, field
from pathlib import Path

from ..agents import render, session
from ..checks import gate
from ..lean import surface
from ..model import acquisition, blueprint, corpus, definitions as definitions_mod, nodeid, ontology
from ..model.blueprint import ConceptRecord, Node, normalize_concept
from ..store import jsonl, paths
from . import candidate as candidate_phase
from . import label_check, review

REQUEST_TYPES = ("semantic", "sweep_relation", "performance", "coverage", "generation")
#: Where a change request goes, by its object: the outer loop's request file, or the operator's queue.
OUTER = ("core", "ontology", "prompt")
OPERATOR = ("corpus", "adapter", "label", "parameter", "inherited")
OUTER_FILE, OPERATOR_FILE = "outer_requests.jsonl", "operator_queue.jsonl"


# ---------------------------------------------------------------------------------------------
# The session's output
# ---------------------------------------------------------------------------------------------
@dataclass
class Output:
    """What a label repair session wrote: revised `records` (nodes and concepts), `withdrawals`
    (each `{"node_id", "withdraw": {...}}`), the Lean `diff`, the change `requests`, and the `errors`
    that make it unreadable (an empty output is one)."""
    records: list = field(default_factory=list)
    withdrawals: list[dict] = field(default_factory=list)
    diff: str = ""
    requests: list[dict] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)


def request_errors(reqs) -> list[str]:
    """The defects of a `change_request.json` against its one schema."""
    if not isinstance(reqs, list):
        return ["change_request.json is a list of requests"]
    out = []
    for i, r in enumerate(reqs, 1):
        if not isinstance(r, dict):
            out.append(f"request {i} is not an object"); continue
        if r.get("type") not in REQUEST_TYPES:
            out.append(f"request {i}: type {r.get('type')!r} is not one of {list(REQUEST_TYPES)}")
        if r.get("object") not in OUTER + OPERATOR:
            out.append(f"request {i}: object {r.get('object')!r} is not one of {list(OUTER + OPERATOR)}")
        for k in ("target", "words", "evidence"):
            if not isinstance(r.get(k), str) or not r[k].strip():
                out.append(f"request {i}: `{k}` is a non-empty string" + (" (or \"not applicable\")" if k == "words" else ""))
    return out


def read_output(d: Path, nodes: dict[str, dict]) -> Output:
    """The one reader of a label repair's output. A node record keeps the `law_refs` and the
    segmentation of the run's record of its id (`nodes`, the candidate's); a node id the run does not
    hold is a new cut, the planner's (a withdrawal of kind `plan`)."""
    out = Output()
    f = d / "record.jsonl"
    for i, line in enumerate([l for l in f.read_text(encoding="utf-8").splitlines() if l.strip()] if f.exists() else [], 1):
        try:
            r = json.loads(line)
        except json.JSONDecodeError as e:
            out.errors.append(f"line {i} of record.jsonl is not JSON: {e}"); continue
        if not isinstance(r, dict):
            out.errors.append(f"line {i} of record.jsonl is not one JSON object"); continue
        if r.get("withdraw"):
            if r.get("node_id") not in nodes:
                out.errors.append(f"line {i}: a withdrawal names the `node_id` of a node of the run ({r.get('node_id')!r} is none)"); continue
            w = r["withdraw"]
            out.withdrawals.append({"node_id": r["node_id"], "withdraw": dict(w) if isinstance(w, dict) else {"missing": str(w)}})
        elif isinstance(r.get("concept_id"), str):
            out.records.append(ConceptRecord({**normalize_concept(r)}))
        elif isinstance(r.get("node_id"), str):
            if r["node_id"] not in nodes:
                out.errors.append(f"line {i}: `{r['node_id']}` is no node of the run; a new cut of a law is the planner's "
                                  "(withdraw with kind `plan`)"); continue
            planned = nodes[r["node_id"]]
            out.records.append(Node({**{k: planned[k] for k in ("law_refs", "segmentation") if k in planned},
                                     **{k: v for k, v in r.items() if k not in ("law_refs", "segmentation")}}))
        else:
            out.errors.append(f"line {i}: a record carries its `node_id` or its `concept_id`")
    if (d / "lean.diff").exists():
        out.diff = (d / "lean.diff").read_text(encoding="utf-8")
    if (d / "change_request.json").exists():
        try:
            reqs = json.loads((d / "change_request.json").read_text(encoding="utf-8"))
            errs = request_errors(reqs)
            out.errors += errs
            out.requests = [] if errs else reqs
        except json.JSONDecodeError as e:
            out.errors.append(f"change_request.json is not JSON: {e}")
    if any(w["withdraw"].get("kind") == "concept" for w in out.withdrawals) and not (d / "dependency_defect.json").is_file():
        out.errors.append("a `concept` withdrawal comes with its `dependency_defect.json`")
    if not out.errors and not (out.records or out.withdrawals or out.diff.strip() or out.requests):
        out.errors.append("the output holds no revised record, no Lean change, no change request and no withdrawal: it is refused")
    return out


# ---------------------------------------------------------------------------------------------
# Lean written by the repair
# ---------------------------------------------------------------------------------------------
def _mapping(kind: str, rec: dict) -> dict:
    """What each span of a record maps to, span by span (never as one set)."""
    out: dict = {}
    for e in rec.get("elements") or []:
        if isinstance(e, dict):
            key = sorted(e.get("concepts") or []) if kind == "concept" else sorted(e.get("derived") or [])
            out.setdefault(str(e.get("span")), []).append((sorted(e.get("atoms") or []), key))
    for o in rec.get("operationalizations") or []:
        if isinstance(o, dict):
            out.setdefault(f"op:{o.get('span')}", []).append(sorted(blueprint.concepts_of(o)))
    return {k: sorted(v, key=str) for k, v in out.items()}


def _strip(x):
    """A record part without its prose justifications: what it maps, not why."""
    if isinstance(x, dict):
        return {k: _strip(v) for k, v in x.items() if k not in ("justification", "why", "narrative")}
    if isinstance(x, list):
        return [_strip(v) for v in x]
    return x


#: The parts of a node record besides its spans' mapping whose change is a change of the rule's
#: structure: the coder writes it again.
STRUCTURE = ("subject", "binders", "compositions", "rule_sets", "cases", "permission", "purposes", "operationalizations", "occasion", "assumptions", "intentions", "facts")


def not_local(kind: str, old: dict, new: dict) -> list[str]:
    """Why a revised record's Lean is not the repair's to write: its segmentation, its mapping span
    by span, its parameters, its structure (subject, binders, the rules it composes and how, its
    operationalizations, its occasion, its declared facts), or (a concept) its interface changed.
    Empty when the change is local."""
    out = []
    if kind == "node":
        if old.get("segmentation") != new.get("segmentation"):
            out.append("the segmentation changed")
        if Node(old).params() != Node(new).params():
            out.append("the parameters changed")
        out += [f"its {k} changed" for k in STRUCTURE if _strip(old.get(k)) != _strip(new.get(k))]
    elif candidate_phase.interface(old) != candidate_phase.interface(new):
        out.append("the interface changed")
    if _mapping(kind, old) != _mapping(kind, new):
        out.append("a span maps to other atoms or concepts")
    return out


class DiffRefused(ValueError):
    pass


def _rel(path: str) -> str:
    for prefix in ("a/", "b/"):
        if path.startswith(prefix):
            path = path[len(prefix):]
    return path[len("library/"):] if path.startswith("library/") else path


def diff_files(text: str) -> list[str]:
    """The library files a unified diff writes, relative to the library."""
    lines = text.splitlines()
    return sorted({_rel(l[4:].split("\t")[0].strip()) for i, l in enumerate(lines)
                   if l.startswith("+++ ") and i and lines[i - 1].startswith("--- ") and "/dev/null" not in l})


def apply_diff(text: str, library: Path, allowed: set[str]) -> dict[str, str]:
    """The new text of each file a unified diff writes, computed on a copy (nothing in `library`
    changes): refused (`DiffRefused`) when it writes a file not shown to the session, creates or
    deletes one, or does not apply to the text shown."""
    files = diff_files(text)
    if not files:
        raise DiffRefused("lean.diff writes no file")
    outside = [f for f in files if f not in allowed]
    if outside or any(l.startswith("+++ /dev/null") or (l.startswith("--- /dev/null") and i + 1 < len(text.splitlines()))
                      for i, l in enumerate(text.splitlines())):
        raise DiffRefused(f"lean.diff writes {outside or 'a new or a deleted file'}, not among the files shown")
    lines = text.splitlines()
    head = {i for i, l in enumerate(lines) if l.startswith("--- ") and i + 1 < len(lines) and lines[i + 1].startswith("+++ ")}
    head |= {i + 1 for i in head}                     # a file's two header lines; a removed line `-- …` reads `--- …` too
    norm = "\n".join((l[:4] + _rel(l[4:].split("\t")[0].strip())) if i in head else l for i, l in enumerate(lines)) + "\n"
    with tempfile.TemporaryDirectory() as t:
        for f in files:
            (Path(t) / f).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(library / f, Path(t) / f)
        p = subprocess.run(["patch", "-p0", "--batch", "--forward", "--no-backup-if-mismatch", "-d", t],
                           input=norm, capture_output=True, text=True)
        if p.returncode != 0:
            raise DiffRefused("lean.diff does not apply to the files shown: " + (p.stdout + p.stderr).strip()[-600:])
        return {f: (Path(t) / f).read_text(encoding="utf-8") for f in files}


# ---------------------------------------------------------------------------------------------
# The session
# ---------------------------------------------------------------------------------------------
def law_nodes(view, law: str) -> dict[str, dict]:
    return {i: r for i, r in view.all_nodes().items() if Node(r).law == law}


def shown_files(view, law: str) -> list[str]:
    """The law's rules and witnesses and the concepts they call, directly or through other concepts:
    the files a repair's Lean change is written against."""
    from ..loop import concept_closure, concept_deps
    refs = {c: set(ConceptRecord(r).refs()) for c, r in view.all_concepts().items()}
    nodes = law_nodes(view, law)
    called = set()
    for r in nodes.values():
        called |= concept_closure(concept_deps(Node(r)), refs)
    out = [p for i in sorted(nodes) for p in candidate_phase.own_files("node", i)]
    out += [p for c in sorted(called & set(view.all_concepts())) for p in candidate_phase.own_files("concept", c)]
    return [p for p in out if (paths.LIBRARY / p).exists()]


def write_records(txn, law_of: dict) -> Path:
    """Every record of the run the repair may change, one file each under the candidate's
    `records/`: the record with its law's text (a node) or its callers (a concept)."""
    d = txn.area / "records"
    d.mkdir(parents=True, exist_ok=True)
    view = txn.view
    for nid, r in view.accepted_nodes.items():
        law = law_of.get(Node(r).law)
        (d / f"{nid}.json").write_text(json.dumps({"record": r, "law": {"id": law.id, "text": law.text} if law else None},
                                                  ensure_ascii=False, indent=1), encoding="utf-8")
    for cid, r in view.accepted_concepts.items():
        (d / f"{cid}.json").write_text(json.dumps({"record": r, "callers": r.get("callers", [])}, ensure_ascii=False, indent=1),
                                       encoding="utf-8")
    return d


def allow(d: Path, txn) -> list[str]:
    """What a label repair session may do: read and write its own directory, and read the candidate's
    rules, concepts and witnesses and the run's records it may change (`records/`)."""
    lib = txn.library
    reads = [lib / "TrafficSpec" / "Rules", lib / "TrafficSpec" / "Concepts", lib / "TrafficSpecWitness", txn.area / "records"]
    return [f"{t}({session._abs(d)}/**)" for t in ("Read",) + session.WRITE_TOOLS] + [f"Read({session._abs(p)}/**)" for p in reads]


def prompt_for(run, txn, law: corpus.Law, defs: list[dict], onto, repairs: int) -> str:
    """The `node_repair.md` prompt for a law during a law-level label repair."""
    return render.render("node_repair.md", prompt_parts(run, txn, law, defs, onto, repairs))


#: The parts of a repair's prompt that are the law's own (its text, records, state and Lean); with its
#: label evidence they are what a session's answer was given on (`input_digest`).
INPUTS = ("law", "node", "verdict", "final_files")


def input_digest(run, parts: dict, st: dict) -> str:
    """What a repair session was asked on: the law's own parts of its prompt and its label evidence.
    The reports on a concept are left out: a report judged again is the same repair's, not a new input."""
    return candidate_phase._sha([parts[k] for k in INPUTS] + [(run.dir / st["evidence"]).read_text(encoding="utf-8")])


def previous_block(st: dict) -> str:
    """How the law's previous repair ended, when it published nothing, and what its candidate did not
    pass, check by check (a check that decided nothing among them): diagnostics of a candidate that
    was rolled back, never a ruling on the accepted library."""
    last = st.get("last_repair")
    if not last:
        return ""
    out = [f"\nThe previous label repair of this law (iteration {last.get('iteration')}, candidate `{last.get('candidate')}`) published "
           f"nothing: {last.get('outcome')}."]
    if last.get("failed"):
        out.append("What its candidate did not pass (the diagnostics of that rolled-back candidate, not rulings on the accepted library):")
        out += [f"- {r['check']} `{r['subject']}`: {r['status']}" + "".join(f"; {x}" for x in r.get("details", [])) for r in last["failed"]]
    return "\n".join(out) + "\n"


def prompt_parts(run, txn, law: corpus.Law, defs: list[dict], onto, repairs: int) -> dict[str, str]:
    st = run.label_states[law.id]
    return {**law_parts(run, txn, law, defs, onto),
            "verdict": (f"## The law's state\n\nLabel check: {st['outcome']} ({st['coverage']['matched']} of {st['coverage']['eligible']} "
                        f"plain label(s) match). Repair goal: {label_check.goal_for(st['outcome'])}. Label repair {repairs + 1} of {run.opts.label_repair_attempts} "
                        "for this law.\n" + previous_block(st)),
            "evidence": (run.dir / st["evidence"]).read_text(encoding="utf-8") + reports_block(st.get("reports", [])) + source_block(run, st)}


def law_parts(run, txn, law: corpus.Law, defs: list[dict], onto) -> dict[str, str]:
    """The parts of a law-level repair's `node_repair.md` prompt that are the law's and the
    vocabulary's own, the same for a label and a review repair: every part but `verdict` and `evidence`."""
    from .plan import parameter_catalogue, declaration_catalogue, definitions_for, FIXED_NODE_KEYS
    view = txn.view
    nodes = law_nodes(view, law.id)
    seg = "\n".join(f"- `{s['id']}` ({s['role']}): {s['text']}" for s in (next(iter(nodes.values()), {}).get("segmentation") or []))
    files = []
    with txn.inside():
        for rel in shown_files(view, law.id):
            files.append(f"```lean\n-- {rel}\n{(paths.LIBRARY / rel).read_text(encoding='utf-8')}\n```")
    reading = txn.reading
    return {
        "law": f"## The law\n\n**{law.id}** — {law.title}\n\n{law.text}\n\nSpans (the segmentation of its nodes):\n{seg}\n",
        "definitions": "## Definitions that apply\n\n" + corpus.render_definitions(definitions_for(run, [law]))
                       + definitions_mod.render_sources(definitions_mod.cited_sources(run, [law], [Node(r) for r in nodes.values()]),
                                                        definitions_mod.CITED_HEADING),
        "node": "## The nodes of the law (every one yours to revise)\n\n" + "\n".join(
            f"`{i}`:\n```json\n{json.dumps({k: v for k, v in r.items() if k not in FIXED_NODE_KEYS or k == 'node_id'}, ensure_ascii=False, indent=1)}\n```"
            for i, r in sorted(nodes.items())) + "\n",
        "coder_narrowings": "## What the coder narrowed\n\n(each record carries its narrowings)\n",
        "task_result": "(no coding session ran for this repair)",
        "final_files": "\n".join(files) or "(no file)", "ontology": onto.text, "formula_language": surface.formula_language(),
        "concept_language": surface.concept_language(), "concepts": surface.concepts_table(view.all_concepts(), surface.current_callers(view)),
        "parameters": "## Parameters\n\n" + parameter_catalogue(reading) + acquisition.standard_note(getattr(run.opts, "acquisition_profile", None))
                      + declaration_catalogue(reading),
        "anchors": ontology.anchors_text(onto), "aggregate_atom": ontology.AGGREGATE}


def where_to_write(d: Path, txn) -> str:
    return (f"\n\n## Where to write\n\nWorking directory: `{d.resolve()}`. Write there, with the Write tool, what the Output asks "
            "during a law-level label repair: `record.jsonl`, `lean.diff` (its paths as the files are headed above), `change_request.json`, "
            "and `dependency_defect.json` with a `concept` withdrawal. You may read, and not write, the candidate's rules, concepts "
            f"and witnesses under `{txn.library.resolve()}` (`TrafficSpec/Rules`, `TrafficSpec/Concepts`, `TrafficSpecWitness`) "
            f"and every record of the run you may change, with its law or its callers, under `{(txn.area / 'records').resolve()}`. "
            "A record the run inherits is not among them: it is read-only. The shell runs nothing.\n")


OUTPUT_FILES = ("record.jsonl", "lean.diff", "change_request.json", "dependency_defect.json")


def repair_dir(run, law: str) -> Path:
    """The directory of the law's current repair: the active repair's own (`active`), whatever the
    iteration, else a new one (`sessions`, the law's count of repairs begun and ended), so a new
    repair never takes an earlier one's output or completion, and one not ended is resumed in its own
    directory, not paid for again."""
    st = run.label_states.get(law, {})
    if st.get("active"):
        return run.dir / st["active"]["dir"]
    return run.iter / "label_repair" / law / f"repair-{int(st.get('sessions', 0)) + 1:02d}"


def _reask_clean(d: Path, ask: str) -> str:
    """The re-ask of a repair: the first answer is kept whole under `first/`, and every output file
    is cleared, so the second answer is read alone (an output replaces, never adds to, the first)."""
    from .plan import _reask
    keep = d / "first"
    keep.mkdir(exist_ok=True)
    for name in OUTPUT_FILES + ("validation.txt",):
        if (d / name).exists():
            shutil.copy2(d / name, keep / name)
    out = _reask(d, ask)
    for name in OUTPUT_FILES:
        (d / name).unlink(missing_ok=True)
    return out


def run_session(run, txn, law: corpus.Law, defs: list[dict], onto, repairs: int,
                to_user: list[str] | None = None) -> tuple[Path, Output]:
    """The session for a law, with one re-ask on an unreadable output; returns its directory and output.
    The law's active repair is taken up while what it was asked on (`input_digest`) is unchanged;
    asked on what a commit has since changed, its answer is set aside, uncharged, and a new session asked."""
    from .plan import _repair_attempts
    st = run.label_states[law.id]
    parts = prompt_parts(run, txn, law, defs, onto, repairs)
    key = input_digest(run, parts, st)
    if st.get("active") and st["active"].get("input") != key:
        old = st.pop("active")["dir"]
        st["sessions"] = int(st.get("sessions", 0)) + 1
        if to_user is not None:
            to_user.append(f"`{law.id}`: its unfinished label repair ({old}) was asked on what a commit has since changed; "
                           "its answer is not taken up, a new session is asked")
    d = repair_dir(run, law.id)
    st.setdefault("active", {"dir": str(d.relative_to(run.dir)), "input": key, "stage": "session", "iteration": run.iteration})
    d.mkdir(parents=True, exist_ok=True)
    write_records(txn, {l.id: l for l in corpus.load_laws(run.opts.laws)})
    prompt = render.render("node_repair.md", parts) + where_to_write(d, txn)
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    ask, attempts = _repair_attempts(d, prompt)
    out = Output(errors=["no session ran"])
    for attempt in attempts:
        if not session.finished(d, "session" + attempt):
            session.run(ask, cwd=d, out_dir=d, opts=run.opts, max_turns=run.opts.plan_turns, effort=run.opts.plan_effort, role="repair",
                        label="session" + attempt, allow=allow(d, txn), deny=session.deny_rules("plan", run.opts.run_id),
                        tools=session.REPAIR_TOOLS, env=session.harness_env(),
                        relaunch=lambda: [(d / n).unlink(missing_ok=True) for n in OUTPUT_FILES])
        out = read_output(d, txn.view.all_nodes())
        (d / "validation.txt").write_text("\n".join(out.errors) or "accept", encoding="utf-8")
        if not out.errors or attempt:
            return d, out
        ask = _reask_clean(d, prompt + "\n\n## Defects of your previous output\n\nWrite it again without these defects:\n"
                           + "".join(f"- {e}\n" for e in out.errors))
    return d, out


# ---------------------------------------------------------------------------------------------
# Applying the output to the candidate
# ---------------------------------------------------------------------------------------------
def changes_of(txn, out: Output, law: str) -> tuple[list, list[tuple[str, str]], list[str]]:
    """The candidate changes an output makes: (changes, records left to the coder as (kind, id),
    notes). A Lean change applies to a record whose change is local; a revised record whose change is
    not local, or that no Lean change covers, is the coder's."""
    view, notes = txn.view, []
    current = {**{i: ("node", r) for i, r in view.all_nodes().items()}, **{i: ("concept", r) for i, r in view.all_concepts().items()}}
    revised = {(r.raw.get("concept_id") or r.raw.get("node_id")): ("concept" if isinstance(r, ConceptRecord) else "node", r.raw)
               for r in out.records}
    new_text: dict[str, str] = {}
    if out.diff.strip():
        with txn.inside():
            allowed = set(shown_files(view, law))
            new_text = apply_diff(out.diff, txn.library, allowed)
    owner_of = {p: (k, i) for i, (k, _r) in {**current, **revised}.items() for p in candidate_phase.own_files(k, i)}
    touched: dict[str, dict[str, str]] = {}
    for rel, text in new_text.items():
        touched.setdefault(owner_of[rel][1], {})[rel] = text
    changes, coder = [], []
    for ident, (kind, rec) in revised.items():
        old = current.get(ident, (kind, None))[1]
        why = not_local(kind, old, rec) if old else ["a new record"]
        if why or ident not in touched:
            coder.append((kind, ident))
            notes.append(f"`{ident}`: coded in the candidate ({'; '.join(why) or 'no Lean change covers it'})")
            changes.append(candidate_phase.Change(kind, ident, rec))
        else:
            changes.append(candidate_phase.Change(kind, ident, rec, touched[ident]))
    for ident, fs in touched.items():
        if ident not in revised:                                    # Lean changed under an unchanged record: a body corrected
            kind, rec = current[ident]
            changes.append(candidate_phase.Change(kind, ident, {k: v for k, v in rec.items() if k != "fenced"}, fs))
    return changes, coder, notes


def code_in_candidate(txn, records: list[tuple[str, str]], law: str | None = None, earlier: Path | None = None) -> dict[str, dict]:
    """A coding session for each record, in the candidate (its library, its scope, its task
    directories, a gate run from the session gating there); concepts first. A node's registry holds
    only the nodes its own law may compose (`Run.usable_nodes`). A coder's report that a
    concept it calls computes what its contract excludes is judged in the candidate (`judge_report`).
    A `SCOPE_VIOLATION` stops the coding there: that session's report is not judged and no later record
    is coded in a candidate it may have changed outside its files (`_code` then refuses the candidate).
    `earlier`: the candidate where the same repair coded before (`take_up`).
    Returns id → {verdict, report, line}."""
    from . import code as code_phase
    from ..loop import concept_deps, reached_concepts, report_of
    view, out = txn.view, {}
    order = sorted(records, key=lambda x: x[0] != "concept")
    production = paths.LIBRARY.parent                     # the tree that holds the production library, before the copy is in force
    with txn.inside(), gate.candidate_scope(txn.scope):
        txn.write_scope()
        reading = txn.reading
        concepts = sorted(view.all_concepts())
        for kind, ident in order:
            if kind == "concept":
                rec = ConceptRecord(view.all_concepts()[ident])
                task, deps = code_phase.concept_dir(view, ident), set(rec.refs())
                take_up(txn, earlier, kind, rec, task, reading)
                v = code_phase.run_code_concept(view, rec, reading, {"nodes": sorted(view.usable_nodes(None, gated=set(txn.changed))), "concepts": concepts})
            else:
                rec = Node(view.all_nodes()[ident])
                task, deps = code_phase.node_dir(view, ident), concept_deps(rec)
                take_up(txn, earlier, kind, rec, task, reading)
                v = code_phase.run_code(view, rec, reading, {"nodes": sorted(view.usable_nodes(rec.law, gated=set(txn.changed))), "concepts": concepts})
            # the candidate's gate checks the copy: a session that changed the production tree is found by the
            # tree hash the commit requires unchanged, before any report is judged or anything else is coded
            if v.verdict == "SCOPE_VIOLATION" or candidate_phase._sha(gate.repo_digest(production)) != txn.baseline.get("tree"):
                out[ident] = {"verdict": "SCOPE_VIOLATION", "report": "none", "line": "", "concept": None}
                break
            if v.verdict == "OK":
                keep_sources(txn, kind, ident, task)
            rep = report_of(view, task, reached_concepts(view, deps))
            out[ident] = {"verdict": v.verdict, "report": rep.status, "line": rep.line, "concept": rep.concept}
            if rep.status != "none":
                record_report(txn, law, rep, task)
    return out


#: The files a coding task's passing gate judged, kept in its task directory (`keep_sources`).
SOURCES = "sources.json"


def _text_sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def keep_sources(txn, kind: str, ident: str, task: Path) -> None:
    """A record's two files as its passing gate judged them, with their digests, in its task
    directory: what a later candidate of the same repair restores (`take_up`). The task directory is
    part of a run's handoff, a candidate's library copy is not, so a repair left pending is taken up
    the same way on this machine and on another."""
    kept = {}
    for rel in candidate_phase.own_files(kind, ident):
        f = txn.library / rel
        if f.is_file():
            text = f.read_bytes().decode("utf-8")
            kept[rel] = {"sha256": _text_sha(text), "text": text}
    jsonl.write_atomic(task / SOURCES, json.dumps(kept, ensure_ascii=False, indent=1))


def take_up(txn, earlier: Path | None, kind: str, rec, task: Path, reading) -> None:
    """A coding task the same repair ran in an earlier candidate, its gate decided on the context this
    one gives the record (`code.task_context`): its directory, and for a passing gate the two files
    it judged (`keep_sources`, each matching its digest), enter this candidate, so its verdict is
    reused and its report judged again from where its adjudication stopped. On another context, or
    a passing verdict whose files are not kept whole, the record is coded again; so it is when the
    restore itself fails, which leaves no task directory behind (the coder rewrites the files)."""
    from . import code as code_phase
    if earlier is None or task.exists():
        return
    old = earlier / candidate_phase.CANDIDATE_ITER / task.relative_to(txn.view.iter)
    v = jsonl.read_json(old / "verdict.json", {}) or {}
    if v.get("verdict") in (None, code_phase.SESSION_FAILED, gate.INFRA, "SCOPE_VIOLATION") or \
            v.get("extras", {}).get("context") != code_phase.task_context(txn.view, kind, rec.id, rec.raw, reading):
        return
    files = {}
    if v.get("verdict") == "OK":
        kept = jsonl.read_json(old / SOURCES, None) or {}
        files = {rel: x["text"] for rel, x in kept.items() if isinstance(x, dict) and _text_sha(str(x.get("text"))) == x.get("sha256")}
        if set(files) != set(candidate_phase.own_files(kind, rec.id)):
            return
    try:
        for rel, text in files.items():                       # the files first, their directories created: a new record's are not there yet
            (txn.library / rel).parent.mkdir(parents=True, exist_ok=True)
            (txn.library / rel).write_bytes(text.encode("utf-8"))
        shutil.copytree(old, task)
    except OSError as e:
        shutil.rmtree(task, ignore_errors=True)               # never a task directory that looks finished without its files
        print(f"[label_repair] {rec.id}: its earlier coding could not be restored ({e}); coded again")


def judge_report(run, txn, d: Path, law: str):
    """A label repair's report that a concept the law reaches computes what its contract excludes
    (`dependency_defect.json`), judged on the candidate as every such report is, under both
    feedbacks: its form, the concept run on its trace, and the concept adjudicator; never shown a
    recording, a trace of one, a label or an Explain report. The report and its ruling's state are
    kept for the law's evidence (`record_report`)."""
    from ..loop import concept_deps, reached_concepts, report_of
    reached = set()
    for r in law_nodes(txn.view, law).values():
        reached |= reached_concepts(txn.view, concept_deps(Node(r)))
    with txn.inside():
        rep = report_of(txn.view, d, reached)
    record_report(txn, law, rep, d)
    return rep


def record_report(txn, law: str | None, rep, task: Path) -> None:
    """What the law's evidence shows of a report on a concept: the stage its execution reached
    (`DependencyReport.execution`), its ruling apart (`upheld`, `dismissed`, `refused` for a report
    refused before any ruling, `not finished` for one still to be judged), and the contract, body and
    dependency version of the concept it names. Every judgment is kept in the law's `report_history`;
    the law's `reports` hold the current state of each report, one row per identity: the active
    repair, the concept, the report's content and the concept's versions. A report judged again
    replaces its row, wherever its candidate; a different counterexample on the same concept, or the
    same one on a changed concept, is a row of its own."""
    from . import review as review_phase
    from .integrate import context_version
    if law is None:
        return
    acc = txn.view.all_concepts().get(rep.concept) or {}
    try:
        with txn.inside():
            deps = context_version(txn.view, "concept", rep.concept, txn.reading, txn.base) if acc else None
    except (ValueError, KeyError):
        deps = None
    try:
        content = review_phase._digest(json.loads((task / "dependency_defect.json").read_text(encoding="utf-8")))
    except (OSError, json.JSONDecodeError):
        content = None
    st = txn.run.label_states.setdefault(law, {})
    row = {"concept": rep.concept, "status": rep.status, "execution": rep.execution,
           "ruling": RULING.get(rep.status, "not finished"),
           "contract": review_phase.contract_digest(ConceptRecord(acc)) if acc else None,
           "body": review_phase._digest(acc.get("body_json")) if acc else None, "dependencies": deps,
           "repair": (st.get("active") or {}).get("dir"), "report": content,
           "reasons": list(rep.reasons)[:4], "line": rep.line, "task": str(task), "candidate": txn.id}
    st.setdefault("report_history", []).append(row)        # the law's evidence, whatever the candidate becomes
    current = st.setdefault("reports", [])
    same = next((i for i, r in enumerate(current) if report_identity(r) == report_identity(row)), None)
    if same is None:
        current.append(row)
    else:
        current[same] = row


#: A report's ruling by its status; any other status is a ruling not finished.
RULING = {"upheld": "upheld", "dismissed": "dismissed", "protocol": "refused"}
REPORT_IDENTITY = ("repair", "concept", "report", "contract", "body", "dependencies")


def report_identity(row: dict) -> tuple:
    return tuple(row.get(k) for k in REPORT_IDENTITY)


EXECUTION = {"confirmed": "executed, the concept gives what the report says its contract excludes",
             "not_confirmed": "executed, no disagreement shown", "not_run": "not executed"}


def reports_block(rows: list[dict]) -> str:
    """The current state of each report on a concept the law's evidence shows: its execution, and
    its ruling apart. A refused report has no ruling and puts no obligation on the concept."""
    if not rows:
        return ""
    out = ["", "## Reports on a concept", ""]
    for r in rows:
        ruling = ("report refused, no ruling; the concept takes no obligation from it" if r.get("ruling") == "refused"
                  else f"ruling {r.get('ruling')}")
        out.append(f"- `{r['concept']}`: {EXECUTION.get(r.get('execution'), 'execution unknown')}; {ruling}"
                   f" (contract {str(r['contract'])[:12]}, body {str(r['body'])[:12]}, dependencies {str(r['dependencies'])[:12]})"
                   + (f"; {r['line'][:200]}" if r.get("line") else "") + ("; " + "; ".join(r["reasons"])[:300] if r.get("reasons") else ""))
    return "\n".join(out) + "\n"


#: What each case of the source report means, in the order the block lists them.
SOURCE_CASES = (("iii", "declared observed, yet an entity or relation that should carry it lacks it, or a declaration "
                        "contradicts the entities present"),
                ("i", "declared observed, and the recording holds no entity it applies to (a legally empty list)"),
                ("ii", "declared absent: every read of it is unknown"))


def source_block(run, st: dict) -> str:
    """The source report of the law's plain-labelled recordings its committed check left unknown or
    mismatched, as that check stored it from the run's fixed set (nothing computed again): each
    recording's case iii findings by key, flagged where the atom is one its unknown reasons name, its
    case i and ii counts, or that its report was unreadable. A report for the repair session only; it
    shows no adapter wrong, asks no rule to change, and no status, comparison or coverage reads it."""
    chk = jsonl.read_json(run.dir / st["check"], None) if st.get("check") else None
    rep = (chk or {}).get("source_check") or {}
    rows = [s for s in (chk or {}).get("scored", []) if s.get("label") is not None and not s.get("judgment_call")
            and s.get("status") in ("unknown", "mismatch")]
    if not rep or not rows:
        return ""
    out = ["", "## Source diagnostics (report only)", "",
           "Where the manifest of a recording above that is unknown or a mismatch disagrees with its trace, as the source "
           "check found when the run fixed its comparison set. A finding does not show that the adapter is wrong and puts no "
           "obligation on any rule to change; a recording with no finding is not certified correct. No status, comparison, "
           "coverage or concept contract reads it, and no rule or reading may infer `st.on_way` from geometry (containment "
           "or nearness): it is only the source's record. The cases are kept apart:"]
    out += [f"- case {c}: {what};" for c, what in SOURCE_CASES]
    out.append("- unreadable: the recording's report could not be computed, so nothing is known of its source.")
    per, unreadable = rep.get("per_recording", {}), set(rep.get("unreadable", []))
    for s in rows:
        rid = s["recording_id"]
        out += ["", f"### Recording {rid[:12]} (status {s['status']})"]
        if rid in unreadable:
            out.append("- unreadable")
            continue
        r = per.get(rid)
        if r is None:
            out.append("- no source report")
            continue
        tags = [b.get("reason", "").partition(":")[2] for b in s.get("blockers", []) if b.get("reason", "").startswith("absent_atom:")]
        for k in r.get("iii", []):
            lean = k.split(":")[1].replace(".", "_") if ":" in k else ""
            named = lean and any(t == lean or t.startswith(lean + "_") for t in tags)
            out.append(f"- case iii: `{k}`" + (" (its atom is one this recording's unknown reasons name; the entity "
                                               "need not be the one a rule read)" if named else ""))
        if not r.get("iii"):
            out.append("- case iii: none")
        out.append(f"- case i: {r.get('i', 0)} finding(s); case ii: {r.get('ii', 0)} finding(s)")
    return "\n".join(out) + "\n"


def concept_fix(run, txn, rep, d: Path, defs: list[dict], law: str) -> tuple[list, list[tuple[str, str]]]:
    """A concept found defective (upheld) repaired inside the same candidate: its repair session,
    shown the upheld counterexample, revises it under its id (body only, the same-id rule holding) and
    the coder writes it; a split or a withdrawal is no repair here (its callers are planned again)."""
    from .plan import run_repair, read_repair
    rec = ConceptRecord(txn.view.all_concepts()[rep.concept])
    users = [r for r in txn.view.all_nodes().values() if rep.concept in Node(r).claimed_concepts()]
    with txn.inside():
        rd = run_repair(txn.view, rec, [f"upheld: {rep.line}"] + list(rep.reasons), d, defs, users)
    r = read_repair(rd, concept=True)
    if r.kind != "revised" or not r.records:
        return [], []
    new = r.records[0].raw
    return [candidate_phase.Change("concept", rep.concept, {**{k: v for k, v in txn.view.all_concepts()[rep.concept].items()
                                                                 if k == "callers"}, **new})], [("concept", rep.concept)]


def replan(run, txn, law: corpus.Law, defs: list[dict], to_user: list[str]) -> tuple[list, list[tuple[str, str]]]:
    """A law planned again inside the candidate: a plan session over the law alone, its new cut and
    every node (and new concept), the law's old nodes the plan does not keep withdrawn; every record
    of the plan is the coder's. What the plan writes for the operator joins `to_user`, once per note."""
    from .feedback import deliver_operator_notes
    from .plan import operator_notes, run_plan
    with txn.inside():                                 # its validator, run from the session, reads the candidate
        txn.write_scope()
        plan_dir = run_plan(txn.view, [law], defs, tag=f"label-{law.id}", label_repair=True)
    deliver_operator_notes(run, to_user, operator_notes(plan_dir))
    nodes = [n for n in blueprint.load(plan_dir / "blueprint.jsonl") if n.raw.get("law_refs", [None])[0] == law.id]
    if not nodes:
        raise ValueError(f"the plan of `{law.id}` written in the candidate has no node: a law's duties are never withdrawn by a re-plan")
    concepts = [c for c in blueprint.load_concepts(plan_dir / "blueprint.jsonl") if c.id not in txn.view.all_concepts()]
    old = set(law_nodes(txn.view, law.id))
    changes = [candidate_phase.Change("concept", c.id, c.raw) for c in concepts]
    changes += [candidate_phase.Change("node", n.id, n.raw) for n in nodes]
    changes += [candidate_phase.Change("node", i, None) for i in sorted(old - {n.id for n in nodes})]
    return changes, [("concept", c.id) for c in concepts] + [("node", n.id) for n in nodes]


# ---------------------------------------------------------------------------------------------
# One repair, and the repairs of an iteration
# ---------------------------------------------------------------------------------------------
def awaiting(run, ledger) -> list[str]:
    """The planned laws awaiting their label repair, in ledger order; a law whose active repair waits
    on a law not yet accepted (`waits_on`) is not one until that law is, and a law outside the active
    stage's scope is not one in that stage. Under `review: required` a label repair starts only once
    the review allows the law (`behaviour_review.ready`): a finding is repaired first, by its own
    repair; a label repair already begun is taken up again."""
    from ..loop import in_scope, label_scope
    from . import behaviour_review
    scope = label_scope(run)
    return [e.law for e in ledger.entries.values()
            if e.state == "planned" and run.label_states.get(e.law, {}).get("state") == "awaiting_label_repair"
            and in_scope(scope, e.law) and not waits_on(run, ledger, e.law)
            and (run.label_states[e.law].get("active") or behaviour_review.ready(run, ledger, e.law))]


def used(run) -> int:
    return sum(int(st.get("repairs", 0)) for st in run.label_states.values())


class Unavailable(RuntimeError):
    """A part of a repair that did not run (a session, the planner, a coder, a toolchain): nothing of
    the law is judged and nothing is charged; the repair's directory is kept, so its session's answer
    is taken up again, not asked for again."""


class Waiting(RuntimeError):
    """A change that composes a node not usable for building it yet (`candidate.unavailable_compositions`:
    not yet published, its law planned again or held for the operator): no coder runs, nothing is
    charged, and the repair stays active, taken up again from its session's answer once every node it
    waits on is usable."""

    def __init__(self, waits: dict[str, dict[str, str]]):
        super().__init__("; ".join(f"`{i}` composes " + ", ".join(f"`{d}` ({c})" for d, c in sorted(ds.items())) for i, ds in waits.items())
                         + ", not usable for building yet")
        self.nodes = sorted({d for ds in waits.values() for d in ds})


class Stale(RuntimeError):
    """A saved answer whose composition was valid when it was written, made unusable since by another
    commit (its provider superseded, missing or fenced): the answer is set aside and a new session is
    asked, nothing charged."""


def wait_states(run, ledger, law: str) -> dict[str, str]:
    """Each law whose node a law's active repair waits on (`Waiting`, by node) and which is still not
    usable for building it (`Run.provider_code`), with that law's ledger state: `planned` (a pending
    law, its node not yet published or judged) or a state only the operator ends (`blocked`, `failed`)."""
    from ..model import nodeid
    from ..store.state import Availability, USABLE
    w = (run.label_states.get(law, {}).get("active") or {}).get("waits") or []
    if not w:
        return {}
    av, out = Availability(run, entries=ledger.entries), {}
    for d in w:
        if av.code(d, law) == USABLE:
            continue
        rec = run.all_nodes().get(d)
        owner = Node(rec).law if rec else nodeid.law_of(d)[0]
        if owner in ledger.entries:
            out[owner] = ledger.entries[owner].state
    return out


def waits_on(run, ledger, law: str) -> list[str]:
    """The laws whose nodes a law's active repair waits on (`Waiting`) and which are still not usable."""
    return list(wait_states(run, ledger, law))


class OutOfScope(RuntimeError):
    """A session in the candidate went out of scope: a coder's `SCOPE_VIOLATION` (`idents`, the records
    it coded), or a production tree moved after a session (`production_watch`; `where`, that session's
    directory). Never the repair's defect: the candidate is rolled back unpublished and no label repair
    is counted (`scope_failure`)."""

    def __init__(self, idents: list[str], where: Path | None = None):
        super().__init__(f"a session of the candidate went out of scope ({idents}{f', in {where}' if where else ''})")
        self.idents, self.where = list(idents), where


def scope_failure(run, ledger, law: str, txn, idents: list[str], to_user: list[str]) -> str:
    """A candidate rolled back out of scope (`OutOfScope`), recorded in the production run: one count
    in the ledger entry of the law whose repair opened it, under that law (`Ledger.scope_violation`),
    whichever session went out of scope (a coder, a planner, a concept repair, a judge: `idents` name
    it in the notes and the evidence only), once per candidate (the active repair keeps the candidate it
    counted, saved with the ledger in the same snapshot, so a restart neither loses nor repeats it); and
    a production tree the candidate's sessions changed recorded for the run's dirty pause
    (`production_stray`; scheduling was drained, so only they could move it), which the rollback,
    discarding only the copy, never lifts. Returns `scope_budget` when the law reached `SCOPE_BOUND`
    (held for the operator), else `scope` (the repair waits for its next pass)."""
    from ..store.ledger import SCOPE_BOUND
    act = run.label_states[law].setdefault("active", {})
    if act.get("scope_candidate") != txn.id:
        act["scope_candidate"] = txn.id
        ledger.scope_violation(law, law)
    production_stray(run, law, txn, to_user)
    n = ledger.entries[law].scope_violations.get(law, 0)
    if n >= SCOPE_BOUND:
        why = (f"scope_budget: sessions of its label repair went out of scope {n} times (last: {idents}); "
               "this says nothing of the repair")
        ledger.block(law, [f"decision:{law}"], [why])
        to_user.append(f"`{law}` held for you, no label repair counted: {why} (python -m harness reopen {run.opts.run_id} --laws {law} "
                       "clears the count; it does not lift a pause on files left changed)")
        return "scope_budget"
    to_user.append(f"`{law}`: a session of its label repair went out of scope ({idents}); the candidate was rolled back "
                   "unpublished, no label repair counted; the repair is taken up again on a later pass")
    return "scope"


@contextmanager
def production_watch(txn, law: str):
    """Every session the candidate runs (a label repair session and its re-ask, a plan, a concept
    repair, a coder, a judge) is followed, before its output is read and before anything else starts,
    by the commit's own check of the production tree: its hash (`production_baseline`'s `tree`, over the
    tree that holds the production library) against the one the candidate opened on. A moved tree
    raises `OutOfScope`: later sessions would read what the session changed, and the candidate never
    publishing does not undo that. The session's spend and records stay as it left them.
    It assumes what a candidate already requires: scheduling paused and every task that may write the
    production tree drained (refused otherwise, `NotDrained`), and no other candidate open, so no
    other thread calls `session.run` meanwhile. The original is restored however the block ends, and a
    session that raises is checked all the same."""
    why = txn.scheduling.drained()
    if why:
        raise candidate_phase.NotDrained("a candidate's sessions are watched only while scheduling is paused and drained: " + "; ".join(why))
    production, real = paths.LIBRARY.parent, session.run
    moved = lambda: candidate_phase._sha(gate.repo_digest(production)) != txn.baseline.get("tree")

    def watched(*a, **k):
        where = Path(k.get("out_dir") or k.get("cwd") or ".")
        try:
            out = real(*a, **k)
        except BaseException as e:
            if moved():
                raise OutOfScope([law], where) from e
            raise
        if moved():
            raise OutOfScope([law], where)
        return out
    session.run = watched
    try:
        yield
    finally:
        session.run = real


def production_stray(run, law: str, txn, to_user: list[str]) -> bool:
    """Whether a session of candidate `txn` changed the production tree, by the commit's own check
    (`production_baseline`'s tree hash against the one the candidate opened on); when it did, every
    production file changed is named against the per-file digest the candidate kept
    (`PRODUCTION_DIGEST`) and written as a scope violation of the run (`baseline.json` that digest,
    `stray` the files), so the run's dirty-library pause holds until each is restored. A moved tree
    that cannot be named (no digest kept, or none of its files differs) is written as the whole tree
    (`code.WHOLE_TREE`, the recorded hash), which pauses until the operator restores the whole
    production tree to that hash. Written once per candidate."""
    if candidate_phase.production_baseline(run).get("tree") == txn.baseline.get("tree"):
        return False
    from .code import WHOLE_TREE
    d = run.iter / "code" / f"candidate__{txn.id}"
    if (d / "verdict.json").exists():
        return True
    before = jsonl.read_json(txn.area / candidate_phase.PRODUCTION_DIGEST, None)
    now = gate.repo_digest(paths.LIBRARY.parent)
    stray = sorted(k for k in set(before) | set(now) if before.get(k) != now.get(k)) if isinstance(before, dict) else []
    if not stray:                                     # moved, and no file to name: the whole tree, at its recorded hash
        before, stray = {WHOLE_TREE: txn.baseline.get("tree")}, [WHOLE_TREE]
    d.mkdir(parents=True, exist_ok=True)
    jsonl.write_atomic(d / "baseline.json", json.dumps(before))
    jsonl.write_atomic(d / "verdict.json", json.dumps({"verdict": "SCOPE_VIOLATION", "details": [
        f"a session of candidate {txn.id} changed the production tree: {stray[:8]}"], "extras": {"stray": stray}}))
    to_user.append(f"`{law}`: a session of candidate {txn.id} changed the production tree ({stray[:8]}); "
                   f"restore those files to the digests in {d / 'baseline.json'} (for {WHOLE_TREE!r}: the whole tree to "
                   "that hash): no coding session starts until they are")
    return True


class Pending(RuntimeError):
    """A coder's report on a concept that the adjudication has not decided (`review.NOT_JUDGED`): the
    candidate is not published, nothing is charged, and the repair is taken up again from its coding."""


def repair_law(run, ledger, training, law: corpus.Law, defs: list[dict], onto, gap_ledger, gaps_filed: list, to_user: list[str],
               prog: dict | None = None) -> str:
    """One label repair of `law` (see the module's description). `prog` is the loop's progress of the
    iteration (`to_user` and `gaps_filed` its own lists): a kept repair commits it, with the lines it
    says, in the same snapshot as its state. Returns what became of it:
    `committed` (the law routed again, and every other law the repair checked again), `rolled_back`,
    `requested`, `gap`, `dependency_report` (a report on a concept, judged; when its ruling, or that
    of a coder's report, is not finished, the repair stays active and is taken up again without a new
    session), `refused` (an unreadable output), `unavailable` (a part did not run; nothing charged) or
    `waiting` (a change composes a node of a law not yet accepted; nothing charged, `Waiting`).
    Every way out closes or rolls back its candidate."""
    from .candidate import SCHEDULING, Candidate, ChangeRefused, CommitRefused, concept_review
    st = run.label_states[law.id]
    (st.get("active") or {}).pop("waits", None)
    run.law_entries = ledger.entries                    # the transaction copies the caller's live ledger
    repairs = int(st.get("repairs", 0))
    prior = label_check.committed_checks(run.dir, run.label_states)
    plans = {e.law: list(e.nodes) for e in ledger.entries.values()}      # every law's authoritative final plan
    hook = label_check.label_hook(training, prior, plans, target=law.id, goal=label_check.goal_for(st["outcome"]))
    hooks = (concept_review, hook)
    from . import behaviour_review                     # under `review: required` every law it reaches keeps its review
    if behaviour_review.required(run):
        hooks += (behaviour_review.review_hook(run, ledger, behaviour_review.prior(run, ledger), plans),)
    out, gaps, notes, result = Output(), [], [], ""
    with SCHEDULING.pause(timeout=600):
        txn = Candidate.open(run, hooks=hooks)
        try:
            try:
                training.bind(txn)
            except ValueError as e:                       # the harness's own versions, not the repair: nothing to charge
                raise Unavailable(f"its candidate could not be bound to the run's label versions: {e}") from e
            with production_watch(txn, law.id):
                result = _repair(run, ledger, txn, law, defs, onto, repairs, plans, out, gaps, notes, to_user, prog)
        except Waiting as e:
            result = "waiting"
            run.label_states[law.id]["active"]["waits"] = e.nodes
            to_user.append(f"`{law.id}`: its label repair waits: {e}; no coder ran, nothing charged, taken up again once they are usable")
        except Stale as e:
            result = "stale"
            run.label_states[law.id].pop("active", None)
            to_user.append(f"`{law.id}`: its label repair's saved answer no longer holds ({str(e)[:240]}); set aside, a new session is "
                           "asked, nothing charged")
        except OutOfScope as e:
            result, scoped, where = "scope", e.idents, e.where
        except Pending as e:
            result = "pending"
            to_user.append(f"`{law.id}`: {e}; its candidate is not published, the repair is taken up again, nothing charged")
        except (session.SessionUnavailable, Unavailable) as e:
            result = "unavailable"
            to_user.append(f"`{law.id}`: part of its label repair did not run ({str(e)[:240]}); the law waits, nothing charged")
        except (ChangeRefused, CommitRefused, DiffRefused, ValueError) as e:
            result = "rolled_back"
            st["last_outcome"] = f"refused: {str(e)[:300]}"
            to_user.append(f"`{law.id}`: label repair refused ({str(e)[:240]}); the law awaits its next repair")
        finally:
            if txn.status == "open":                      # no way out leaves a candidate open
                (txn.rollback if txn.changed else txn.close)(f"the repair ended: {result or 'stopped'}")
    st = run.label_states[law.id]
    if result not in ("scope", "committed") and production_stray(run, law.id, txn, to_user):
        # a production tree moved under a candidate that did not commit (the commit's own refusal among them): a scope
        # outcome, never the repair's
        result, scoped, where = "scope", [law.id], None
        st.pop("last_outcome", None); st.pop("last_failed", None)
    if result == "scope":                                # after the rollback, in the production run
        gaps.clear(); out.requests = []                  # nothing a candidate that went out of scope asked for is filed
        result = scope_failure(run, ledger, law.id, txn, scoped, to_user)
        act = st.get("active") or {}
        if result == "scope" and where is not None and act.get("dir") and Path(where).resolve() == (run.dir / act["dir"]).resolve():
            # the repair session itself went out of scope: its answer is kept on disk, never read again; a new one is asked
            st["sessions"] = int(st.get("sessions", 0)) + 1
            st.pop("active", None)
    if result not in ("unavailable", "pending", "waiting", "committed", "scope", "stale"):   # decided: its session is spent, the next one is new (a commit counted it)
        st["sessions"] = int(st.get("sessions", 0)) + 1
        st.pop("active", None)
    if result in ("rolled_back", "refused", "requested", "gap", "dependency_report"):
        st.update(repairs=repairs + 1, last_repair={"iteration": run.iteration, "candidate": txn.id,
                                                    "outcome": st.pop("last_outcome", result), "failed": st.pop("last_failed", [])})
    file_requests(run, law.id, out.requests, to_user)
    if result == "requested":
        ledger.block(law.id, [f"decision:{law.id}"], [f"label repair filed change request(s): {[r['object'] for r in out.requests]}"])
    from ..loop import _file_gap
    for w in gaps:
        n = Node(txn.view.all_nodes().get(w["node_id"]) or {"node_id": w["node_id"], "law_refs": [law.id]})
        span = w["withdraw"].get("span")
        gid, _decided = _file_gap(gap_ledger, {"span": span, "kind": w["withdraw"].get("kind"), "proposal": w["withdraw"].get("missing", ""),
                                               "nearest": w["withdraw"].get("nearest", []), "span_text": n.spans().get(span, {}).get("text", ""),
                                               "law_refs": [law.id], "node_id": n.id}, run.opts.run_id, run.iteration, gaps_filed)
        ledger.block(law.id, [gid], [f"label repair withdrew span {span}: {w['withdraw'].get('missing', '')}"])
    return "dependency_report" if result == "pending" else result


def _repair(run, ledger, txn, law, defs, onto, repairs, plans, out: Output, gaps: list, notes: list, to_user: list[str],
            prog: dict | None = None) -> str:
    from ..loop import label_state, route_entry
    st = run.label_states[law.id]
    d, read = run_session(run, txn, law, defs, onto, repairs, to_user)
    out.__dict__.update(read.__dict__)
    if out.errors:
        st["last_outcome"] = "refused: " + "; ".join(out.errors[:3])
        to_user.append(f"`{law.id}`: its label repair output was refused ({'; '.join(out.errors[:2])})")
        return "refused"
    kinds = {w["withdraw"].get("kind") for w in out.withdrawals}
    changes, coder = [], []
    if "concept" in kinds:
        rep = judge_report(run, txn, d, law.id)
        if rep.status in review.NOT_JUDGED:         # no ruling yet: the same report is judged again, no new session
            st["active"]["stage"] = "report"
            to_user.append(f"`{law.id}`: its report on a concept is not finished ({rep.status}); judged again later, nothing charged")
            return "pending"
        if rep.status != "upheld":
            st["last_outcome"] = f"report on `{rep.concept}`: {rep.status}"
            to_user.append(f"`{law.id}`: its label repair reported a concept defect: {rep.status}")
            return "dependency_report"
        changes, coder = concept_fix(run, txn, rep, d, defs, law.id)
        if not changes:
            st["last_outcome"] = f"concept `{rep.concept}` upheld defective; its repair did not revise it under its id"
            return "dependency_report"
        notes.append(f"concept `{rep.concept}` found defective (upheld) and repaired in the candidate")
        kinds, out.records, out.diff = set(), [], ""
    if kinds & {"atom", "operator"}:
        gaps += [w for w in out.withdrawals if w["withdraw"].get("kind") in ("atom", "operator")]
        return "gap"
    if "plan" in kinds:
        more, coder = replan(run, txn, law, defs, to_user)
        changes = changes + more
        plans[law.id] = sorted(c.ident for c in more if c.kind == "node" and c.record is not None)
        notes.append("the law was planned again in the candidate")
    if out.records or out.diff.strip():
        more, more_coder, more_notes = changes_of(txn, out, law.id)
        changes, coder, notes[:] = changes + more, coder + more_coder, notes + more_notes
    if not changes:
        return "requested"
    txn.apply(changes)
    unusable = candidate_phase.unavailable_compositions(txn.view, [c.ident for c in changes if c.kind == "node"], gated=set(txn.changed))
    if unusable:
        from ..store.state import base_code, FENCED, MISSING, SUPERSEDED
        before = run.all_nodes()
        terminal = {i: {d: c for d, c in ds.items() if base_code(c) in (FENCED, MISSING, SUPERSEDED)} for i, ds in unusable.items()}
        new = {i: {d: c for d, c in ds.items() if d not in {str(x.get("rule")) for x in Node(before.get(i) or {}).dependencies()}}
               for i, ds in terminal.items()}
        if any(new.values()):                         # the repair itself composed a record that cannot be used: its output's defect
            raise ValueError("the repair composes records not usable for building: " + "; ".join(
                f"`{i}` → " + ", ".join(f"`{d}` ({c})" for d, c in ds.items()) for i, ds in new.items() if ds))
        if any(terminal.values()):                    # a composition it kept, made unusable by another commit since its answer
            raise Stale("; ".join(f"`{i}` → " + ", ".join(f"`{d}` ({c})" for d, c in ds.items()) for i, ds in terminal.items() if ds))
        raise Waiting(unusable)
    _code(txn, coder, law.id)
    results = txn.verify()
    failed = [r.subject for r in results if r.check == "gate" and r.status == "fail" and r.subject in txn.changed
              and (txn.changed[r.subject], r.subject) not in coder]
    if failed:                                       # Lean the repair wrote that the gate refused: the coder's, in the same candidate
        _code(txn, [(txn.changed[i], i) for i in failed], law.id)
        notes.append(f"coded in the candidate after the gate refused the repair's Lean: {failed}")
        results = txn.verify()
    if any(r.status == "unavailable" for r in results):
        raise Unavailable("; ".join(f"{r.check} {r.subject}: {(r.details or [''])[0]}" for r in results if r.status == "unavailable")[:400])
    if not all(r.status == "pass" for r in results):
        bad = [f"{r.check} {r.subject}: {r.status} ({(r.details or [''])[0]})" for r in results if r.status != "pass"]
        txn.rollback("; ".join(bad[:4]))
        st["last_outcome"] = "rolled back: " + "; ".join(bad[:3])
        st["last_failed"] = [{"check": r.check, "subject": r.subject, "status": r.status, "details": [str(x)[:400] for x in r.details[:3]]}
                             for r in results if r.status != "pass"][:12]
        to_user.append(f"`{law.id}`: label repair rolled back ({'; '.join(bad[:2])}); the law awaits its next repair")
        return "rolled_back"
    chk = txn.label_checks[law.id]
    nodes = sorted(plans[law.id])
    routed = txn.route(law.id, nodes)                # every route the commit carries, derived from the verified results alone
    # the label states, merged at the commit onto their values then: the check's own fields; the target's counts
    # take this commit's one increment, and its session ends; another law keeps its counts and its session
    now = run.label_states.get(law.id, {})
    from ..loop import context_base, label_key, semantic_inputs, staged
    # in a run with a stage record, each state is keyed on the candidate it was checked on, never on the run before it:
    # its records, its reading and its library's files (in force inside it), under the run's own context base
    base = context_base(run.opts, semantic_inputs(run.opts)) if staged(run) else None

    def keyed(l, ns):
        if base is None:
            return None
        with txn.inside():
            return label_key(run, l, list(ns), base=base, view=txn.view, reading=txn.reading)
    updates = {law.id: {**label_state(run, law.id, chk, nodes, txn.area / "label", txn.id, key=keyed(law.id, nodes)),
                        "repairs": int(now.get("repairs", 0)) + 1,
                        "sessions": int(now.get("sessions", 0)) + 1, "active": None}}
    for other, c in txn.label_checks.items():
        if other != law.id and other in run.label_states and other in ledger.entries:
            old = run.label_states[other]
            updates[other] = {k: v for k, v in label_state(run, other, c, old["nodes"], txn.area / "label", txn.id,
                                                            key=keyed(other, old["nodes"])).items() if k != "repairs"}
    # what the commit says, from what it publishes: a law's outcome is its update's, its state the route's
    said = list(routed.said) + [f"`{other}`: checked again by the repair of `{law.id}`: {updates[other]['outcome']}; "
                                f"its law is {(routed.entries.get(other) or ledger.entries[other]).state}" for other in updates if other != law.id]
    said.append(f"`{law.id}`: label repair kept (goal met); the law is {chk.outcome}" + "".join(f"; {n}" for n in notes))
    # the iteration's progress, with these lines, in the commit's snapshot: a stop past its commit point resumes with them said
    from ..store.state import prog_paths
    txn.commit(routed=routed, label_updates=updates,
               extra_state=None if prog is None else {"prog": prog_paths({**prog, "to_user": to_user + said}, paths.stored)})
    for l, e in routed.entries.items():               # the ledger in memory as committed
        if l in ledger.entries:
            ledger.entries[l].__dict__.update({k: getattr(txn.published["ledger"][l], k) for k in candidate_phase.LEDGER_SEMANTIC}
                                              if l in txn.published["ledger"] else {})
    to_user.extend(said)
    return "committed"


def _code(txn, records: list[tuple[str, str]], law: str) -> None:
    """The coder for these records in the candidate, taking up what the same repair coded in an
    earlier candidate (`take_up`); a coder that did not run, or whose report on a concept no one
    decided, is no failed repair. A coding session that ended `SCOPE_VIOLATION` stops the candidate
    (`OutOfScope`): it is rolled back, never committed, and nothing of it is published."""
    from . import code as code_phase
    from ..checks import gate as gate_mod
    if not records:
        return
    act = txn.run.label_states[law].get("active") or {}
    earlier = txn.run.dir / act["candidate"] if act.get("candidate") and txn.run.dir / act["candidate"] != txn.area else None
    act.update(stage="coding", candidate=str(txn.area.relative_to(txn.run.dir)))
    reports = code_in_candidate(txn, records, law, earlier)
    scope = [i for i, x in reports.items() if x.get("verdict") == "SCOPE_VIOLATION"]
    if scope:
        raise OutOfScope(scope)
    down = [i for i, x in reports.items() if x.get("verdict") in (code_phase.SESSION_FAILED, gate_mod.INFRA)]
    if down:
        raise Unavailable(f"the coding session or the toolchain did not run for {down}")
    undecided = {i: x["report"] for i, x in reports.items() if x.get("report") in review.NOT_JUDGED}
    if undecided:                                    # a coder's report no one decided: the candidate waits for its ruling
        raise Pending(f"a coder's report on a concept is not decided ({undecided})")
    upheld = [x for x in reports.values() if x.get("report") == "upheld"]
    if upheld:                                       # a coder showed a concept it calls wrong: the callers wait for its repair
        raise ValueError(f"a coder's dependency-defect report was upheld: {upheld[0].get('line', '')[:200]}")


def file_requests(run, law: str, requests: list[dict], to_user: list[str]) -> None:
    """Each change request into the outer loop's request file or the operator's queue, by its object,
    once: a request of the same law, object, target and words is one entry, a repeat adding its
    evidence and iteration to it. Every request a repair files is announced, a repeat included, once
    among the lines said so far: a repair taken up again after a stop files it again and says so,
    since what it said before the stop was not saved."""
    for r in requests:
        name = OUTER_FILE if r["object"] in OUTER else OPERATOR_FILE
        rows = jsonl.read_strict(run.dir / name)
        key = (law, r["object"], r["target"], r["words"])
        same = next((x for x in rows if (x.get("law"), x.get("object"), x.get("target"), x.get("words")) == key), None)
        seen = {"evidence": r["evidence"], "iteration": run.iteration}
        if same is None:
            rows.append({**r, "law": law, "run": run.opts.run_id, "iteration": run.iteration, "seen": [seen]})
        elif seen not in same.setdefault("seen", []):
            same["seen"].append(seen)
        jsonl.write_rows(run.dir / name, rows)
        line = f"`{law}`: change request on {r['object']} `{r['target']}` filed in {name}"
        if line not in to_user:                       # a repair taken up again with the same answer says it once
            to_user.append(line)


def run_repairs(run, ledger, training, by_id: dict, defs: list[dict], onto, gap_ledger, gaps_filed: list, to_user: list[str],
                prog: dict | None = None, persist=None) -> dict[str, list[str]]:
    """Every law awaiting its label repair, repaired while it awaits one and its budget and the run's
    allow: a law that spent its sessions is held for the operator; the run's budget spent, the laws
    left wait; a production tree a session left changed (`code.scope_unrestored`) starts none. Under
    `review: required`, with `persist` (the loop's commit of its state), a law whose review stands on a
    finding with repairs left first has its review repair (`behaviour_review.repair_finding`: its own
    goal and count, the label hook keeping every law's matches), and its label repair starts in the
    same pass only once the review allows the law; a caller that passes no `persist` runs no review
    repair. `prog`, the loop's progress, is committed with each kept repair of either kind. Returns
    law → the result of each repair, a review repair's prefixed `review:`."""
    from . import behaviour_review, code as code_phase
    out: dict[str, list[str]] = {}
    if code_phase.scope_unrestored(run):
        return out
    findings = set(behaviour_review.work(run, ledger)["repair"]) if persist is not None else set()
    first = awaiting(run, ledger)
    labels = set(first)
    for law in ([law for law in ledger.entries if law in findings | labels] if findings else first):   # in ledger order
        if law in findings and law in behaviour_review.work(run, ledger)["repair"]:    # an earlier commit may have settled it
            r = behaviour_review.repair_finding(run, ledger, law, training, persist, to_user, prog)
            out.setdefault(law, []).append(f"review:{r}")
            if r == "committed":                            # its candidate is closed: the records it changed are the run's now
                from .aggregate import write_current_view
                write_current_view(run, closure=True)
            if code_phase.scope_unrestored(run):
                return out
            if law not in labels and law in awaiting(run, ledger):    # the review allows it now: its label repair may start
                labels.add(law)
        if law not in labels:
            continue
        while run.label_states.get(law, {}).get("state") == "awaiting_label_repair" and ledger.entries[law].state == "planned":
            if int(run.label_states[law].get("repairs", 0)) >= run.opts.label_repair_attempts:
                ledger.block(law, [f"decision:{law}"], [f"its own label repair attempts are spent (--label_repair_attempts, {run.opts.label_repair_attempts}); "
                                                         "the law still disagrees with its labels"])
                to_user.append(f"`{law}`: its label repairs are spent and it still disagrees with its labels; held for you")
                break
            if used(run) >= run.opts.label_repair_budget:
                to_user.append(f"`{law}`: the run's label repair budget ({run.opts.label_repair_budget}) is spent; the law waits")
                return out
            r = repair_law(run, ledger, training, by_id[law], defs, onto, gap_ledger, gaps_filed, to_user, prog)
            out.setdefault(law, []).append(r)
            if r == "committed":                            # its candidate is closed: the records it changed are the run's now
                from .aggregate import write_current_view
                write_current_view(run, closure=True)
            if code_phase.scope_unrestored(run):            # a production tree left dirty stops every law
                return out
            if r in ("scope", "scope_budget"):              # this pass ends here
                break
            if r in ("unavailable", "stale") or run.label_states.get(law, {}).get("active"):    # not ended: taken up again later
                break
    return out
