"""Integrate: registries, whole-library build, every witness, composition DAG. A failure is
attributed to the candidates that caused it, never to the newest ones by default.

The result has a status:
- `verified`: the library builds and every witness holds with the kept candidates;
- `candidates_rejected`: some candidates were removed, each for a failure attributed to it (or to a
  candidate it depends on, in which case it is `waiting`, not rejected);
- `infrastructure`: the toolchain or the witness harness did not run, or the reading does not decode;
  nothing is removed and nothing is charged;
- `baseline_broken`: the library without this iteration's candidates does not verify (an accepted
  node's witness fails, or a file outside the candidates breaks the build); nothing is charged.
"""
from __future__ import annotations
import json
import re
import shutil
import time
from pathlib import Path
from ..lean import index_sync, lean, surface
from ..store import paths
from ..checks import gate, validate_a
from ..model import nodeid
from ..model.blueprint import Node
from ..model.reading import Reading
from ..store.state import Run
from .code import rollback, rollback_concept, node_dir, concept_dir, _files_digest


def _witness_harness(reading_json: Path) -> str:
    return f'''import TrafficSpec
import TrafficSpecWitness
import TrafficSpec.Core.Runtime.Decode
open TrafficSpec
def main : IO Unit := do
  let text ← IO.FS.readFile {json.dumps(str(reading_json))}
  match Decode.parse Decode.reading text with
  | .error e => IO.println s!"READING_DECODE\\t{{e}}"
  | .ok ρ => do
    for f in TrafficSpecWitness.failures ρ do IO.println s!"FAIL\\t{{f}}"
    IO.println s!"RULES\\t{{allRules.length}}\\tSCENARIOS\\t{{TrafficSpecWitness.allScenarios.length}}"
    IO.println "DONE"
'''


def _owner_of_path(line: str) -> str | None:
    """The node or concept whose rule, concept or witness file an error line names, else None."""
    m = re.search(r"(TrafficSpec(?:Witness)?/[\w/.-]+?\.lean)", line)
    if not m:
        return None
    rel = m.group(1)
    if "/Concepts/" in rel:
        return nodeid.concept_id_of_path(rel.replace("TrafficSpecWitness/Concepts/", "TrafficSpec/Concepts/"))
    if rel.startswith("TrafficSpec/Rules/") or (rel.startswith("TrafficSpecWitness/") and "/Concepts/" not in rel):
        return Path(rel).stem
    return None


def verify_library(work: Path, reading: Reading, only_nodes: list[str] | None = None,
                   only_concepts: list[str] | None = None) -> tuple[str, list[str], set[str]]:
    """(status, problems, owners): status `verified`, `failed` (owners name the nodes and concepts
    a failing witness or a failing file belongs to; an error no owner explains leaves `owners`
    short) or `infrastructure` (the build or the harness did not run for a reason no node owns,
    or the reading does not decode). With `only_*`, the registries hold those ids alone (a run's own
    accepted records), not every file on disk. Each build and witness run, and the lock, is timed
    in `toolchain.jsonl` beside them."""
    work.mkdir(parents=True, exist_ok=True)
    with gate._timed(work, "lock", lean.library_lock(paths.LIBRARY)):
        index_sync.write_index(only_nodes=only_nodes, only_concepts=only_concepts)
        t0 = time.monotonic()
        code, out = lean.lake_build(paths.LIBRARY); ok = code == 0
        gate._record(work, "build", code, out, time.monotonic() - t0)
        (work / "build.log").write_text(out, encoding="utf-8")
        if not ok:
            errs = lean.errors(out)
            owners = {o for o in (_owner_of_path(l) for l in errs) if o}
            if not errs:
                return "infrastructure", ["library build did not run"] + out.splitlines()[-4:], set()
            return "failed", ["library build failed"] + errs[:8], owners
        rj = work / "reading.json"; rj.write_text(reading.lean_json(), encoding="utf-8")
        h = work / "witness_harness.lean"; h.write_text(_witness_harness(rj), encoding="utf-8")
        t0 = time.monotonic()
        code, hout = lean.lean_run(paths.LIBRARY, h); ok = code == 0
        gate._record(work, "witnesses", code, hout, time.monotonic() - t0)
    (work / "witness_harness.out").write_text(hout, encoding="utf-8")
    decode = [l for l in hout.splitlines() if l.startswith("READING_DECODE\t")]
    if decode:
        return "infrastructure", ["the reading does not decode: " + decode[0].split("\t", 1)[1]], set()
    if not ok or "DONE" not in hout:
        return "infrastructure", ["witness harness did not run"] + lean.errors(hout)[:8], set()
    fails = [l.split("\t", 1)[1] for l in hout.splitlines() if l.startswith("FAIL\t")]
    owners = {f.split("\t", 1)[0] for f in fails}
    return ("verified" if not fails else "failed"), fails, owners


def _files(kind: str, ident: str) -> list[str]:
    if kind == "concept":
        return [nodeid.concept_path(ident), nodeid.concept_witness_path(ident)]
    return [nodeid.rule_path(ident), nodeid.witness_path(ident)]


def run_integrate(run: Run, accepted_now: list[Node], reading: Reading, baselines: dict[str, dict],
                  concepts_now: list[str] | None = None, concept_baselines: dict[str, dict] | None = None,
                  concept_refs: dict[str, set[str]] | None = None, held: dict[str, str] | None = None) -> dict:
    """Integrate this iteration's candidates. Returns {"status", "kept", "kept_concepts",
    "rejected": {id: reason}, "waiting": {id: reason}, "problems"}; a rejected or waiting candidate's
    files are rolled back, and its immutable snapshot is kept under `integrate/candidates/`. `held`
    names candidates that wait before anything is verified (one that uses a fenced record), with
    the candidates that depend on them."""
    concepts_now = list(concepts_now or [])
    concept_baselines = concept_baselines or {}
    concept_refs = concept_refs or {}
    work = run.iter / "integrate"; work.mkdir(parents=True, exist_ok=True)
    nodes = {n.id: n for n in accepted_now}
    kind = {**{c: "concept" for c in concepts_now}, **{n: "node" for n in nodes}}
    # what each candidate depends on among the candidates: concepts it calls, nodes it composes
    deps: dict[str, set[str]] = {c: set(concept_refs.get(c, set())) & set(concepts_now) for c in concepts_now}
    for n in accepted_now:
        from ..loop import concept_deps
        deps[n.id] = ({c.get("rule") for c in n.dependencies()} & set(nodes)) | (concept_deps(n) & set(concepts_now))
    snap = work / "candidates"
    for ident, k in kind.items():                      # the immutable snapshot of every candidate, taken once
        for rel in _files(k, ident):
            src, dst = paths.LIBRARY / rel, snap / rel
            if src.exists() and not dst.exists():
                dst.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(src, dst)
    rejected: dict[str, str] = {}
    waiting: dict[str, str] = {}

    def remove(ident: str) -> None:
        if kind[ident] == "concept":
            rollback_concept(ident, concept_baselines.get(ident, {}), concept_dir(run, ident))
        else:
            rollback(ident, baselines.get(ident, {}), node_dir(run, ident))

    def restore(ident: str) -> None:
        for rel in _files(kind[ident], ident):
            if (snap / rel).exists():
                (paths.LIBRARY / rel).parent.mkdir(parents=True, exist_ok=True); shutil.copy2(snap / rel, paths.LIBRARY / rel)

    def dependents(ident: str) -> set[str]:
        out, frontier = set(), {ident}
        while frontier:
            frontier = {c for c, ds in deps.items() if ds & frontier and c not in out and c != ident}
            out |= frontier
        return out

    def drop(ident: str, why: str) -> None:
        if ident in rejected or ident in waiting:
            return
        rejected[ident] = why
        remove(ident)
        for d in dependents(ident):
            if d not in rejected and d not in waiting:
                waiting[d] = f"depends on `{ident}`, rejected at integration"
                remove(d)

    for ident, why in (held or {}).items():
        if ident in kind and ident not in waiting:
            waiting[ident] = why
            remove(ident)
            for d in dependents(ident):
                if d not in rejected and d not in waiting:
                    waiting[d] = f"depends on `{ident}`, which waits: {why}"
                    remove(d)
    all_nodes = {k: Node(v) for k, v in run.accepted_nodes.items()}
    all_nodes.update(nodes)
    for why, members in validate_a.acyclic(all_nodes):
        for i in members:
            if i in nodes:
                drop(i, why)
    status, problems = "verified", []
    for _round in range(len(kind) + 1):
        st, problems, owners = verify_library(work, reading)
        if st == "verified":
            status = "verified" if not rejected and not waiting else "candidates_rejected"
            break
        if st == "infrastructure":
            status = "infrastructure"
            break
        live = {i for i in kind if i not in rejected and i not in waiting}
        named = owners & live
        if owners - set(kind):                          # an accepted node's witness, or a file outside the candidates
            status = "baseline_broken"
            break
        if named:
            for i in sorted(named):
                drop(i, "library did not verify: " + "; ".join(p for p in problems if p.startswith(f"{i}\t") or i in p)[:300])
            continue
        # nothing names a candidate: rebuild from the verified baseline, one dependency-closed candidate at a time
        for i in live:
            remove(i)
        st0, problems0, _o = verify_library(work, reading)
        if st0 != "verified":
            for i in live:
                restore(i)
            status = "infrastructure" if st0 == "infrastructure" else "baseline_broken"
            problems = problems0
            break
        # the verified set starts as the baseline and grows by each candidate that verifies when added,
        # in dependency order: a candidate is tried only once everything it depends on is in the set
        verified: set[str] = set()
        pending = [c for c in concepts_now if c in live] + [n.id for n in accepted_now if n.id in live]
        infra = False
        while pending and not infra:
            ready = [i for i in pending if deps.get(i, set()) <= verified]
            if not ready:                                # what is left depends on a candidate that did not verify
                for i in pending:
                    if i not in rejected and i not in waiting:
                        waiting[i] = "a candidate it depends on was rejected at integration"
                break
            for i in ready:
                pending.remove(i)
                if i in waiting or i in rejected:
                    continue
                restore(i)
                st1, problems1, _o = verify_library(work, reading)
                if st1 == "infrastructure":
                    status, problems, infra = "infrastructure", problems1, True
                    break
                if st1 != "verified":
                    drop(i, "library did not verify with it added to the verified baseline: " + "; ".join(problems1[:2])[:300])
                else:
                    verified.add(i)
        if not infra:
            status = "candidates_rejected" if (rejected or waiting) else "verified"
        break
    if status in ("infrastructure", "baseline_broken"):
        for i in kind:                                  # nothing is removed for a reason no candidate owns
            if i not in rejected and i not in waiting:
                restore(i)
    kept = [n.id for n in accepted_now if n.id not in rejected and n.id not in waiting]
    kept_concepts = [c for c in concepts_now if c not in rejected and c not in waiting]
    result = {"status": status, "kept": kept, "kept_concepts": kept_concepts, "rejected": rejected, "waiting": waiting,
              "problems": problems[:12]}
    (work / "result.json").write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")
    return result


# ---------------------------------------------------------------------------------------------
# A candidate's dependency context: what its verdicts were established on
# ---------------------------------------------------------------------------------------------
def _digest(x) -> str:
    import hashlib
    return hashlib.sha256(json.dumps(x, sort_keys=True, ensure_ascii=False, default=str).encode()).hexdigest()


def semantic_record(rec: dict) -> dict:
    """What a record means, without the fields other records or the harness write onto it."""
    from ..store.state import NOT_SEMANTIC
    return {k: v for k, v in rec.items() if k not in NOT_SEMANTIC}


def context_parts(run: Run, kind: str, ident: str, reading: Reading, base: dict, seen: frozenset = frozenset(),
                  record: dict | None = None, catalogue: dict | None = None, semantic: bool = False) -> dict:
    """The dependency context of a node or concept, computed from the library and the run as they
    are now: the record itself (without the fields others write onto it) and its files (the
    binders, applicability and obligation, or the body), the versions of the concepts it calls and
    the rules it composes (each with its own context) and whether each is fenced, the reading values
    and units it reads with whether each is reviewed or still proposed, the admitted aggregates it
    claims with their entries, the definition sources it borrows words from as the corpus posts them
    now (each with the definitions that apply to it; a node that borrows none has no such part), and
    `base` (Core, the ontology, the review configuration). `record`
    and `catalogue` (`{"nodes", "concepts"}`) give a candidate not yet accepted and the records it
    may use; a candidate's own files are left out (its session writes them; the gate's candidate
    digest holds them). With `semantic`, the obligations recorded on it are part of it too. A cycle
    is rejected before expansion."""
    from ..model.blueprint import ConceptRecord
    if ident in seen:
        raise ValueError(f"a dependency cycle through `{ident}`")
    seen = seen | {ident}
    nodes = catalogue["nodes"] if catalogue is not None else run.all_nodes()
    concepts = catalogue["concepts"] if catalogue is not None else run.all_concepts()
    if kind == "node":
        rec = record if record is not None else nodes[ident]
        n = Node(rec)
        from ..loop import concept_deps
        files = (nodeid.rule_path(ident), nodeid.witness_path(ident))
        calls, composed = concept_deps(n), [c.get("rule") for c in n.dependencies() if c.get("rule") in nodes]
        params, claims = n.params(), n.claimed_atoms()
        own = {"record": _digest(semantic_record(rec))}
    else:
        rec = record if record is not None else concepts[ident]
        c = ConceptRecord(rec)
        files = (nodeid.concept_path(ident), nodeid.concept_witness_path(ident))
        calls, composed = {r for r in c.refs() if r in concepts}, []
        params, claims = [], c.claimed_atoms()
        own = {"record": _digest(semantic_record(rec)), "contract": " ".join(str(rec.get("contract", "")).split()),
               "body": _digest(rec.get("body_json"))}
    aggs = sorted(a.split("=", 1)[1] for a in claims if a.startswith("ru.aggregate="))
    fenced = getattr(run, "fenced", {}) or {}
    sub = {"nodes": nodes, "concepts": concepts}
    out = {"files": _files_digest(files) if record is None else None, **own,
           "concepts": {c: context_version(run, "concept", c, reading, base, seen, catalogue=sub) for c in sorted(calls) if c in concepts},
           "composed": {r: context_version(run, "node", r, reading, base, seen, catalogue=sub) for r in sorted(composed)},
           "fences": {d: (fenced.get(d) or {}).get("reason") for d in sorted(set(calls) | set(composed)) if d in fenced},
           "reading": {p: [(reading.params.get(p) or {}).get("value"), (reading.params.get(p) or {}).get("unit"),
                           "proposed" if (reading.params.get(p) or {}).get("proposed") else "reviewed"] for p in sorted(set(params))},
           "aggregates": {a: _digest(reading.aggregate(a)) for a in aggs}, **base}
    if kind == "node" and Node(rec).definition_sources():
        from ..model import definitions as definitions_mod
        out["sources"] = {s: (definitions_mod.source_digest(r) if (r := definitions_mod.source_record(run, s)) else None)
                          for s in Node(rec).definition_sources()}
    if semantic:
        out["obligations"] = obligations_version(run, ident)
    return out


def borrowed_words_defects(run: Run, n: Node) -> list[str]:
    """A node's `definition` references whose source is no longer in the active corpus, or no longer
    holds the quoted words: the meaning its elements carry is no longer the source's."""
    from ..model import definitions as definitions_mod
    out = []
    for c in n.definition_references():
        rec = definitions_mod.source_record(run, str(c.get("source")))
        if rec is None:
            out.append(f"the definition source `{c.get('source')}` of span {c.get('span')} is no longer in the run's corpus")
        elif " ".join(str(c.get("quote", "")).split()) not in " ".join(rec["text"].split()):
            out.append(f"the definition source `{c.get('source')}` of span {c.get('span')} no longer holds the quoted words")
    return out


def context_version(run: Run, kind: str, ident: str, reading: Reading, base: dict, seen: frozenset = frozenset(),
                    record: dict | None = None, catalogue: dict | None = None, semantic: bool = False) -> str:
    return _digest(context_parts(run, kind, ident, reading, base, seen, record, catalogue, semantic))[:24]


def obligations_version(run: Run, ident: str) -> str:
    """The rulings recorded on a record (its subject's effective rows): a ruling added, superseded or
    changed in state changes it."""
    from . import review as review_phase
    try:
        rows = [r for r in review_phase.effective_rows(review_phase._all_rows(run)) if r.get("subject") == ident]
    except (OSError, AttributeError):
        rows = []
    return _digest([(r.get("ruling_id"), r.get("ruling"), r.get("obligation")) for r in rows])[:24]


#: The modules every gate check is made of: a change to any of them is a change to the gate.
GATE_SOURCES = ("harness/checks", "harness/lean", "harness/model/units.py", "harness/model/reading.py", "harness/model/blueprint.py",
                "harness/model/acquisition.py")


def gate_digest() -> str:
    """A digest of the gate's implementation: every module it calls."""
    files = []
    for rel in GATE_SOURCES:
        p = paths.REPO / rel
        files += sorted(p.rglob("*.py")) if p.is_dir() else [p]
    return _digest({str(f.relative_to(paths.REPO)): f.read_text(encoding="utf-8") for f in files if f.exists()})[:24]


def admission_key(run: Run, kind: str, ident: str, reading: Reading, base: dict, record: dict | None = None,
                  catalogue: dict | None = None, gate_value: str | None = None) -> str:
    """What a gate verdict on a record rests on: the record's context without its obligations,
    the gate's implementation (`gate_value`, when the caller computed `gate_digest` already), and the
    acquisition standard the run holds `heading_since` to."""
    from ..model import acquisition
    return _digest({"context": context_version(run, kind, ident, reading, base, record=record, catalogue=catalogue),
                    "gate": gate_value or gate_digest(),
                    "acquisition": acquisition.standard_digest(getattr(run.opts, "acquisition_profile", None))})[:24]


#: Admission timeouts of one record under one admission key before its recheck at each launch is
#: paused: the record stays without evidence (`unjudged`), an operational pause, never a fence; only
#: `harness reopen --admission` (or a change of the key) lets it be timed again.
ADMISSION_TIMEOUT_BOUND = 2


def read_admission(run) -> dict:
    """The admission file of a run (or of a candidate's view): {id: entry}; a file that cannot be read
    is read as empty, as a cache."""
    f = getattr(run, "admission_file", None) or run.dir / "admission.json"
    try:
        d = json.loads(f.read_text(encoding="utf-8")) if f.exists() else {}
    except (OSError, json.JSONDecodeError):
        d = {}
    return d if isinstance(d, dict) else {}


def entry_kind(entry) -> str:
    """What an admission entry is, decided before it is used: `verdict` (it holds a `verdict`; only a
    verdict `OK` under the record's current key is evidence), `timeout` (it holds `timeouts` and no
    verdict: never evidence) or `other` (any other shape: no evidence, the gate is run again and the
    entry overwritten)."""
    if isinstance(entry, dict) and "verdict" in entry:
        return "verdict"
    if isinstance(entry, dict) and isinstance(entry.get("timeouts"), int) and not isinstance(entry.get("timeouts"), bool):
        return "timeout"
    return "other"


def admission_paused(run, ident: str, key: str) -> dict | None:
    """The record's timeout entry when it has reached `ADMISSION_TIMEOUT_BOUND` under `key`, else None."""
    hit = read_admission(run).get(ident)
    if entry_kind(hit) == "timeout" and hit.get("key") == key and hit["timeouts"] >= ADMISSION_TIMEOUT_BOUND:
        return hit
    return None


def recheck_contexts(run: Run, reading: Reading, base: dict, laws: dict, only: set[str] | None = None) -> tuple[list[str], list[str], list[str]]:
    """Every accepted record of the run's effective view (its base chain's and its own) whose
    dependency context changed since it was last checked, or that has no recorded context at all (a
    record accepted before contexts were recorded is checked, never assumed sound), mechanically:
    - a node's `definition` references, against the posted sources they quote
      (`borrowed_words_defects`); `laws` must hold the posted law of every node of the view, the
      inherited ones included (`state.chain_laws`);
    - a concept's upheld challenges, run on its body: one the body confirms again, or one that can no
      longer be run as recorded (its record fails today's schema), is a failure;
    - a concept's open structural finding is a failure (it was never discharged).
    A record that passes has its context recorded (on the record for the run's own, in
    `run.rechecked` for an inherited one), only then. A record that fails is fenced (`fenced`, reason
    `context`), never reused silently. A check that could not be made (a node whose law is in no
    corpus, a concept program that did not run) decides nothing: the record is neither fenced nor
    given a context, and it is listed as unresolved. Returns (the ids rechecked
    and found sound; lines for the operator about those fenced; lines about those unresolved). With
    `only`, the records checked are those it names."""
    from . import review as review_phase
    from ..model.blueprint import ConceptRecord
    ok, failing, unresolved = [], [], []
    rechecked = getattr(run, "rechecked", None)
    if rechecked is None:
        rechecked = run.rechecked = {}
    rows = review_phase.effective_rows(review_phase._all_rows(run))
    for kind, records in (("concept", run.all_concepts()), ("node", run.all_nodes())):
        own = run.accepted_concepts if kind == "concept" else run.accepted_nodes
        for ident, rec in records.items():
            if ident in run.fenced or (only is not None and ident not in only):
                continue
            try:
                now = context_version(run, kind, ident, reading, base, semantic=True)
            except (ValueError, KeyError) as e:
                failing.append(f"`{ident}`: its dependency context cannot be computed: {e}")
                run.fence(ident, kind, "context", evidence=str(e)[:300])
                continue
            was = own[ident].get("context") if ident in own else rechecked.get(ident, rec.get("context"))
            if was == now:
                continue
            problems, undecided = [], []
            if kind == "node":
                n, law = Node(rec), laws.get(Node(rec).law)
                if law is None:
                    unresolved.append(f"`{ident}`: its law `{n.law}` is in no corpus of the run or its base chain, so it cannot "
                                      "be checked; nothing was decided")
                    continue
                problems += borrowed_words_defects(run, n)
            else:
                mine = [r for r in rows if r.get("subject") == ident and r.get("ruling") == "upheld"]
                problems += [f"an open structural finding of iteration {r.get('iteration')} was never discharged"
                             for r in mine if r.get("schema") == review_phase.CONCEPT_STRUCTURAL_SCHEMA and r.get("obligation") in ("open", None)]
                c = ConceptRecord(rec)
                cases = [r for r in mine if r.get("schema") == review_phase.CONCEPT_CASE_SCHEMA]
                if cases:
                    dim = review_phase.body_dim(c, rec.get("body_json")) if c.get("kind") == "quantity" else None
                    divs = [{x: r.get(x) for x in review_phase.CONCEPT_CASE_FIELDS if r.get(x) is not None} for r in cases]
                    try:
                        confirmed, _agree, errors, incomplete = review_phase.execute_concept_divergences(
                            c, {"divergences": divs}, run.iter / "recheck" / ident, dim, reading, saved=True,
                            registry=review_phase._registry(run, ident, None))
                    except review_phase.HarnessFailure as e:
                        confirmed, errors, incomplete = [], [], []
                        undecided.append(f"the concept program did not run: {e}")
                    problems += [f"its body contradicts its contract again on an upheld challenge: {review_phase._shown(x)}" for x in confirmed]
                    problems += [f"an upheld challenge cannot be run on it: {surface.shorten(x, 200)}" for x in errors + incomplete]
            if problems:
                line = (f"`{ident}` ({kind}): its context changed since it was last checked, or was never recorded, and it no "
                        "longer meets its obligations — " + "; ".join(problems[:3]))
                failing.append(line)
                run.fence(ident, kind, "context", evidence=surface.shorten("; ".join(problems[:3]), 600))
            elif undecided:
                unresolved.append(f"`{ident}` ({kind}): its obligations could not be checked — " + "; ".join(undecided[:2]))
            else:
                if ident in own:
                    own[ident]["context"] = now
                else:
                    rechecked[ident] = now
                ok.append(ident)
    return ok, failing, unresolved


# ---------------------------------------------------------------------------------------------
# Admission: every accepted record held to today's gates; a failure is fenced, with its closure
# ---------------------------------------------------------------------------------------------
class AdmissionUnavailable(Exception):
    """A gate that did not judge a record (the toolchain, a deadline): the record is not fenced."""


def fence_closure(run: Run) -> list[str]:
    """Fence every accepted record that calls or composes a fenced one, directly or through others
    (reason `dependency`, naming the provider), to a fixed point. Returns the ids fenced here."""
    from ..model.blueprint import ConceptRecord
    from ..loop import concept_deps
    concepts, nodes = run.all_concepts(), run.all_nodes()
    uses = {cid: set(ConceptRecord(r).refs()) for cid, r in concepts.items()}
    uses.update({nid: concept_deps(Node(r)) | {c.get("rule") for c in Node(r).dependencies()} for nid, r in nodes.items()})
    added, grown = [], True
    while grown:
        grown = False
        for ident, used in uses.items():
            if ident in run.fenced:
                continue
            hit = sorted(used & set(run.fenced))
            if hit:
                run.fence(ident, "concept" if ident in concepts else "node", "dependency", provider=hit[0],
                          evidence=f"calls or composes the fenced `{hit[0]}`")
                added.append(ident); grown = True
    return added


def admission_selection(run: Run, kind: str, ident: str) -> dict:
    """What one record's admission gate registers: the record, the nodes it composes and, through
    them, theirs, and every concept those nodes or it call, directly or through other concepts.
    Nothing else of the library enters its build, so an unrelated record that does not compile is
    not this record's verdict. `missing` names the composed ids the view holds no record of: they
    are never silently dropped, and a caller that needs the whole closure treats them as an error."""
    from ..model.blueprint import ConceptRecord
    from ..loop import concept_deps, concept_closure
    nodes, concepts = run.all_nodes(), run.all_concepts()
    refs = {c: set(ConceptRecord(r).refs()) for c, r in concepts.items()}
    if kind == "concept":
        return {"nodes": [], "concepts": sorted(concept_closure({ident}, refs) & set(concepts)), "keep": [ident], "missing": []}
    seen, frontier = set(), {ident}
    while frontier:
        seen |= frontier
        frontier = {c.get("rule") for i in frontier if i in nodes for c in Node(nodes[i]).dependencies()} - seen
    used = {c for i in seen if i in nodes for c in concept_deps(Node(nodes[i]))}
    return {"nodes": sorted(seen & (set(nodes) | {ident})), "concepts": sorted(concept_closure(used, refs) & set(concepts)), "keep": [ident],
            "missing": sorted(i for i in seen if i not in nodes and i != ident)}


def record_admitted(run: Run, records: list[tuple[str, str]], reading: Reading, base: dict, iteration: int) -> None:
    """Enter in the admission cache each record (`(kind, id)`) the run's own gate accepted in this
    iteration, under the key the next loop start's admission recheck computes, so that recheck runs
    no gate for it while nothing its verdict rests on has changed. A fenced record is left out."""
    from ..store import jsonl
    cache = read_admission(run)
    for kind, ident in records:
        if ident not in run.fenced:
            cache[ident] = verdict_entry(cache.get(ident), admission_key(run, kind, ident, reading, base), "OK",
                                         [f"accepted by the run's own gate in iteration {iteration}"])
    jsonl.write_atomic(run.dir / "admission.json", json.dumps(cache, indent=1, ensure_ascii=False))


def verdict_entry(was, key: str, verdict: str, details: list[str]) -> dict:
    """A verdict entry; a pass keeps the record's earlier timeouts as `timeout_history` (history: no
    evidence, and no longer counted towards a pause)."""
    out = {"key": key, "verdict": verdict, "details": details}
    if verdict == "OK" and entry_kind(was) == "timeout":
        out["timeout_history"] = {"timeouts": was["timeouts"], "timeout_seconds": was.get("timeout_seconds", 0.0),
                                  "resets": list(was.get("resets", []))}
    return out


def dependency_blocker(run: Run, kind: str, ident: str) -> str | None:
    """Of the records a dependency-fenced record uses now (the nodes it composes, the concepts it
    calls, as its record names them), the first that still blocks it: fenced, or not usable
    (`Run.provider_code`); None when none does."""
    from ..model.blueprint import ConceptRecord
    from ..store.state import Availability, USABLE
    from ..model.nodeid import is_concept_id
    av = Availability(run)
    rec = run.all_concepts().get(ident) if kind == "concept" else run.all_nodes().get(ident)
    if rec is None:
        return None
    if kind == "concept":
        uses = [("concept", c) for c in sorted(ConceptRecord(rec).refs()) if is_concept_id(c)]
    else:
        n = Node(rec)
        uses = [("node", str(c.get("rule"))) for c in n.dependencies() if c.get("rule")] + [("concept", c) for c in sorted(n.claimed_concepts())]
        law = n.law
    for k, p in uses:
        if p in run.fenced:
            return p
        code = av.concept_code(p) if k == "concept" else av.code(p, law)
        if code != USABLE:
            return p
    return None


def lift_fence(run: Run, ident: str, why: str) -> None:
    """A fence that no longer holds goes to `fence_history`, with why it was lifted."""
    f = run.fenced.pop(ident, None)
    if f is not None:
        run.fence_history.append({**f, "id": ident, "lifted": why})


def admission_recheck(run: Run, reading: Reading, base: dict, unjudged: list[str] | None = None,
                      notes: list[str] | None = None) -> dict[str, dict]:
    """Rerun today's gates on every accepted record of the effective view, the concepts a record calls
    before it, each gate registering only that record and what it uses (`admission_selection`). Each
    record's entry in `admission.json` is read by its kind (`entry_kind`) before it is used:
    - a verdict entry under the record's current admission key (its context without its obligations,
      the gate's implementation, the acquisition standard) is reused: no gate runs for it;
    - a timeout entry under the current key below `ADMISSION_TIMEOUT_BOUND` lets the gate run once
      more; at the bound the record is not timed again (an operational pause: it stays without
      evidence, `unjudged`, and is listed in `unjudged`);
    - an entry under another key, or of another shape (reported in `notes`), is no entry.
    A gate that rejects the record fences it (reason `gate`, its verdict as evidence and the key it
    was rejected under), and everything that calls it (`fence_closure`); the operational selection
    (`.inactive.json`) is rewritten before the next gate. A fence of reason `gate` holds only while the
    record's admission key is the one it names: under another key it goes to `fence_history` at once
    and the current version is held to today's gate: a pass gives it evidence, a rejection fences it
    under the new key, a timeout or a panic leaves it unjudged (never fenced). A fence of reason `dependency` is evaluated again from the record's current
    providers (`dependency_blocker`): it stays, naming the provider that still blocks it, until every
    provider is usable; then it is lifted and the record is held to its own recheck here under its
    current key. Every other fence (`context`, a concept's `dependency_defect`, a fence without a key)
    stays. Returns {id: verdict} of the records fenced here.

    With `unjudged`, a gate that exceeded its deadline is no judgement: the record gets no evidence
    and is not fenced, its timeout entry counts it (`timeouts` + 1, `timeout_seconds` summed) under the
    current key, and a line naming it is appended to `unjudged`; a panic in isolation is reported as
    a Core defect and counted nowhere. A pass writes a verdict entry, the earlier timeouts kept as
    `timeout_history`. Without `unjudged`, such a gate raises `AdmissionUnavailable`, as does a gate
    that did not judge the record because the toolchain did not run."""
    from ..checks import gate
    from ..model.blueprint import ConceptRecord
    from ..loop import concept_order, topological
    from ..store import jsonl
    cache = read_admission(run)
    cache_file = run.dir / "admission.json"
    notes = notes if notes is not None else []
    out: dict[str, dict] = {}
    gd = gate_digest()
    concepts = [ConceptRecord(r) for r in run.all_concepts().values()]
    nodes = [Node(r) for r in run.all_nodes().values()]
    order = [("concept", c.id, c) for c in concept_order(concepts)] + [("node", n.id, n) for n in topological(nodes)]
    for kind, ident, rec in order:
        if fence_closure(run) or out:
            index_sync.set_inactive(set(run.fenced), run.opts.run_id)
        f = run.fenced.get(ident)
        key = None
        if f is not None:
            if f.get("reason") == "gate" and f.get("key"):
                key = admission_key(run, kind, ident, reading, base, gate_value=gd)
                if key == f["key"]:
                    continue                                  # rejected under the key it has now
                # a rejection holds only for its own key: retired now, whatever the new key's gate says (a pass, a
                # rejection fenced under the new key, or a timeout or panic, which leave the record unjudged)
                lift_fence(run, ident, "its admission key changed; the earlier rejection held only for its own key")
                notes.append(f"`{ident}`: its admission key changed, so its earlier rejection no longer stands; it is held to "
                             "today's gate under the new key")
                index_sync.set_inactive(set(run.fenced), run.opts.run_id)
            elif f.get("reason") == "dependency":
                blocker = dependency_blocker(run, kind, ident)
                if blocker is not None:
                    if blocker != f.get("provider"):
                        run.fenced[ident] = {**f, "provider": blocker, "evidence": f"calls or composes `{blocker}`, which is fenced or not usable"}
                    continue
                lift_fence(run, ident, "every record it calls or composes is usable again")
                notes.append(f"`{ident}`: its dependency fence is lifted, every record it uses being usable again; it is held to its "
                             "own admission and context checks before it is used")
                index_sync.set_inactive(set(run.fenced), run.opts.run_id)
            else:
                continue
        key = key or admission_key(run, kind, ident, reading, base, gate_value=gd)
        hit = cache.get(ident)
        k = entry_kind(hit)
        if k == "verdict" and hit.get("key") == key:
            verdict, details = hit["verdict"], hit.get("details", [])
        elif k == "timeout" and hit.get("key") == key and hit["timeouts"] >= ADMISSION_TIMEOUT_BOUND:
            if unjudged is not None:
                unjudged.append(f"`{ident}`: not rechecked — its admission gate exceeded its deadline {hit['timeouts']} times under its "
                                f"current key ({hit.get('timeout_seconds', 0.0):.0f} s in all); it stays unjudged, an operational pause, "
                                f"until `python -m harness reopen {run.opts.run_id} --laws <a law waiting on it> --admission`")
            continue
        else:
            if hit is not None and k == "other":
                notes.append(f"`{ident}`: its admission entry has no known shape; it is not evidence, the gate runs again and replaces it")
            work = run.dir / "admission" / ident.replace(".", "_")
            work.mkdir(parents=True, exist_ok=True)
            (work / "registry.json").write_text(json.dumps(admission_selection(run, kind, ident)), encoding="utf-8")
            t0 = time.monotonic()
            if kind == "concept":
                v = gate.run_concept_gate(rec, reading, gate.repo_digest(), work, 0, 1, mode="train",
                                          accepted={k2: r for k2, r in run.all_concepts().items() if k2 != ident})
            else:
                v = gate.run_gate(rec, reading, gate.repo_digest(), work, 0, 1, accepted_concepts=run.all_concepts(),
                                  acquisition=run.opts.acquisition_profile)
            took = time.monotonic() - t0
            if v.verdict == gate.GATE_TIMEOUT and unjudged is not None:
                if v.extras.get("panic"):
                    unjudged.append(f"`{ident}`: not rechecked at this launch — its evaluation panicked in isolation (a Core defect) "
                                    f"({'; '.join(v.details[:1])[:200]}); it has no admission evidence and is checked again at the next launch")
                    continue
                was = hit if k == "timeout" and hit.get("key") == key else {}
                entry = {"key": key, "timeouts": int(was.get("timeouts", 0)) + 1,
                         "timeout_seconds": float(was.get("timeout_seconds", 0.0)) + took, "last": time.strftime("%Y-%m-%dT%H:%M:%S")}
                if was.get("resets"):
                    entry["resets"] = list(was["resets"])
                cache[ident] = entry
                jsonl.write_atomic(cache_file, json.dumps(cache, indent=1, ensure_ascii=False))
                unjudged.append(f"`{ident}`: not judged at this launch — its admission gate exceeded its deadline "
                                f"({'; '.join(v.details[:1])[:200]}); timeout {entry['timeouts']} of {ADMISSION_TIMEOUT_BOUND} under its "
                                f"current key, {entry['timeout_seconds']:.0f} s in all; it has no admission evidence and is not fenced")
                continue
            if v.verdict in (gate.INFRA, gate.GATE_TIMEOUT, "BUDGET_EXHAUSTED"):
                raise AdmissionUnavailable(f"`{ident}`: the gate did not judge it ({v.verdict}: {'; '.join(v.details[:2])})")
            verdict, details = v.verdict, v.details[:6]
            cache[ident] = verdict_entry(hit, key, verdict, details)
            jsonl.write_atomic(cache_file, json.dumps(cache, indent=1, ensure_ascii=False))
        if verdict != "OK":
            run.fence(ident, kind, "gate", verdict=verdict, key=key, evidence=f"{verdict}: " + "; ".join(details[:3])[:500])
            out[ident] = {"verdict": verdict, "details": details}
            index_sync.set_inactive(set(run.fenced), run.opts.run_id)
    fence_closure(run)
    index_sync.set_inactive(set(run.fenced), run.opts.run_id)
    return out
