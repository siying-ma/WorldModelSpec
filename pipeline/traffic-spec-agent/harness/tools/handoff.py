"""The handoff of a run between machines: one machine writes the run at a time, and the state it hands
over is a self-contained checkpoint that the next machine verifies before it continues.

A run is pinned to the code that decides its results (`code_digest`: the harness, the recorded-data
code, the monitor and Explain sources, the prompts, Core with its root module, the ontology, the
configuration, the Lean build files, the region-kind exporter the harness runs, the doctor with the
modules it runs, the launcher, and the Python project file with its dependency lock). The operator's
hints a session reads are pinned apart, in the run's directory (`Run.pin_hints`), and travel with it.
Every export carries the baseline the run's first export recorded, and every import and
every resume of a run that has a manifest refuses to continue on other code, other semantic inputs or
another acceptance policy than the run's first export recorded,
naming the files: a later development of the pipeline never changes a run's results. A checkpoint that
only adds run artifacts changes none of those files.

`export` refuses unless the run is at a consistent checkpoint: no other owner of the library, no
candidate commit pending, the last iteration `done` with every coding task decided, the ledgers and
accepted records equal to the snapshot, and the library equal to the run's freeze; and it refuses a run
with a `base_run` chain or `budget_peers`, whose closure it does not carry. It writes
`results/<run>/handoff/manifest.json` (the baseline, the toolchain, the semantic digests, the acceptance
policy and the digest
of every exported file) and `results/<run>/handoff/files.txt` (every exported path, relative to the
agent directory). The library's lock and owner files, build caches, candidate library copies and the
dataset are never exported. Saved operational paths need no rewriting: they are repository-relative or
mapped from the run's recorded roots (`paths.local`)."""
from __future__ import annotations
import hashlib
import json
import subprocess
import sys
import time
import uuid
from pathlib import Path

from ..store import jsonl, paths
from ..store.state import acceptance_policy, acceptance_policy_refusal

#: The files whose content decides a run's results, relative to the agent directory.
CODE_PATTERNS = ("harness/**/*.py", "recorded/**/*.py", "prompts/*", "ontology/*", "config/*",
                 "library/TrafficSpec/Core.lean", "library/TrafficSpec/Core/**/*.lean", "library/Explain.lean",
                 "library/Main.lean", "library/lean-toolchain", "library/lakefile.lean", "library/lake-manifest.json",
                 "scripts/RegionKinds.lean", "scripts/__init__.py", "scripts/diagnostics/*.py", "scripts/gen_ontology.py",
                 "scripts/run-generation.sh", "pyproject.toml", "uv.lock")
#: The split tool the doctor runs, from outside this directory (`paths.ontology_tool`), under its place in the
#: WorldModelSpec layout; recorded as absent (None) where it is not found.
DOCTOR_TOOL = "../ontology_provenance/nrs_tools/atoms_train.py"
#: Names never exported: process locks and owner records, build caches, and this machine's import record.
NEVER = (".lake", "__pycache__", ".run.owner.json", ".run.lock", "imported.json")


def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def code_files() -> list[Path]:
    out = set()
    for pat in CODE_PATTERNS:
        out |= {p for p in paths.REPO.glob(pat) if p.is_file() and "__pycache__" not in p.parts}
    return sorted(out)


def code_digest() -> dict:
    """The code that decides a run's results: each file's sha256 and one digest over them."""
    files = {p.relative_to(paths.REPO).as_posix(): _sha(p) for p in code_files()}
    tool = paths.ontology_tool("atoms_train")                 # the doctor's split tool, beside this directory
    files[DOCTOR_TOOL] = _sha(tool) if tool else None
    return {"files": files, "digest": hashlib.sha256(json.dumps(files, sort_keys=True).encode()).hexdigest()}


def toolchain() -> dict:
    """What the run was built with besides its code (the dependency lock is code): Python, the Lean
    toolchain as `lean --version` reports it and the installed distributions."""
    from importlib import metadata
    lean = "unavailable"
    try:
        p = subprocess.run(["lean", "--version"], cwd=paths.LIBRARY, capture_output=True, text=True, timeout=60)
        lean = p.stdout.strip() or p.stderr.strip()[:200] or f"exit {p.returncode}"
    except (OSError, subprocess.TimeoutExpired) as e:
        lean = f"unavailable ({type(e).__name__})"
    dists = sorted(f"{d.metadata['Name']}=={d.version}" for d in metadata.distributions() if d.metadata["Name"])
    return {"python": ".".join(map(str, sys.version_info[:3])), "lean": lean,
            "distributions": hashlib.sha256("\n".join(dists).encode()).hexdigest()}


def _options(run_id: str) -> dict:
    d = jsonl.read_json(paths.run_dir(run_id) / "options.json", None)
    if d is None:
        raise SystemExit(f"no run `{run_id}` under {paths.RESULTS}")
    paths.register_roots(d.get("repo_roots"))
    return d


def _excluded(rel: Path) -> bool:
    parts = rel.parts
    if any(x in NEVER for x in parts) or rel.name.endswith(".lock"):
        return True
    # a candidate's copy of the library (`.../candidate/<id>/tree/`) is never handed over: what a pending repair
    # takes up from it (a passing coder's two files) is kept with their digests in the task directory, which is
    # handed over (`label_repair.keep_sources`)
    return any(parts[i] == "candidate" and i + 2 < len(parts) and parts[i + 2] == "tree" for i in range(len(parts)))


def artifact_files(run_id: str) -> list[str]:
    """Every file the handoff carries, relative to the agent directory: the run's directory (but its
    `handoff/` record), its library records and registries, its base reading and the gap ledger."""
    opts = _options(run_id)
    out: set[Path] = set()
    rd = paths.run_dir(run_id)
    for p in rd.rglob("*"):
        if p.is_file() and not _excluded(p.relative_to(rd)) and p.relative_to(rd).parts[0] != "handoff":
            out.add(p)
    for root in (paths.RULES_DIR, paths.CONCEPTS_DIR, paths.WITNESS_DIR, paths.GAPS_DIR):
        if root.exists():
            out |= {p for p in root.rglob("*") if p.is_file() and not _excluded(p.relative_to(root))}
    for f in (paths.INDEX_FILE, paths.WITNESS_ROOT_FILE, paths.local(opts.get("base_reading") or opts.get("reading", ""))):
        if f.is_file() and f.resolve().is_relative_to(paths.REPO.resolve()):
            out.add(f)
    return sorted(p.resolve().relative_to(paths.REPO.resolve()).as_posix() for p in out)


def checkpoint_problems(run_id: str) -> list[str]:
    """Why the run is not at a checkpoint another machine may take over (empty when it is)."""
    from ..phases import candidate, label_check
    opts = _options(run_id)
    rd = paths.run_dir(run_id)
    bad = []
    if opts.get("base_run") or opts.get("budget_peers"):
        bad.append("the run uses a base_run chain or budget_peers, whose closure a handoff does not carry")
    if candidate.pending() is not None:
        bad.append("the library holds a candidate commit not yet applied")
    j = jsonl.read_json(rd / candidate.JOURNAL, None)
    if j is not None and j.get("status") != "applied":
        bad.append(f"the run's candidate journal is `{j.get('status')}`, not applied")
    snap = jsonl.read_json(rd / "state.json", None)
    if not snap or not snap.get("prog"):
        return bad + ["the run has no committed iteration"]
    stage = snap["prog"].get("stage")
    if stage != "done":
        bad.append(f"iteration {snap.get('iteration')} stopped at stage `{stage}`, short of `done`")
    it = paths.iter_dir(run_id, int(snap.get("iteration", 0)))
    open_tasks = sorted(d.name for d in (it / "code").glob("*") if d.is_dir() and (d / "baseline.json").exists()
                        and not (d / "verdict.json").exists()) if (it / "code").exists() else []
    if open_tasks:
        bad.append(f"coding task(s) without a verdict: {open_tasks[:6]}")
    rows = lambda f: [json.loads(x) for x in f.read_text(encoding="utf-8").splitlines() if x.strip()] if f.exists() else []
    for name, key in (("ledger.jsonl", "ledger"), ("concept_ledger.jsonl", "concept_ledger"), ("node_ledger.jsonl", "node_ledger")):
        if rows(rd / name) != snap.get(key, []):
            bad.append(f"{name} differs from the snapshot")
    for name, key in (("accepted_nodes.jsonl", "accepted_nodes"), ("accepted_concepts.jsonl", "accepted_concepts")):
        if rows(rd / name) != list((snap.get(key) or {}).values()):
            bad.append(f"{name} differs from the snapshot")
    bad += [f"freeze: {x}" for x in label_check.drift(rd)[:6]]
    return bad


def export(run_id: str, source_baseline: str = "") -> dict:
    """Write the handoff of a run at a checkpoint (see the module's description); refuses otherwise.
    Returns the manifest."""
    from ..store import owner
    owner.acquire_for_command("handoff")                 # the single writer: refused while a loop or command owns the library
    bad = checkpoint_problems(run_id)
    if bad:
        raise SystemExit(f"[handoff] `{run_id}` is not at a checkpoint: " + "; ".join(bad))
    opts = _options(run_id)
    rd = paths.run_dir(run_id)
    hd = rd / "handoff"
    was = jsonl.read_json(hd / "manifest.json", None)
    code = code_digest()
    if was is not None and was.get("baseline", {}).get("code", {}).get("digest") != code["digest"]:
        raise SystemExit("[handoff] " + _code_refusal(was, code))
    snap = jsonl.read_json(rd / "state.json", {}) or {}
    summary = jsonl.read_json(rd / "summary.json", {}) or {}
    files = artifact_files(run_id)
    manifest = {"export_id": uuid.uuid4().hex, "run": run_id, "exported_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
                "iteration": snap.get("iteration"), "stage": (snap.get("prog") or {}).get("stage"),
                "status": summary.get("status"), "stop": summary.get("stop"), "pending": summary.get("pending"),
                "repo_root": str(paths.REPO),
                "baseline": (was or {}).get("baseline") or {"source_commit": source_baseline or None, "code": code},
                "toolchain": toolchain(), "semantic": opts.get("semantic", {}),
                "acceptance_policy": (was or {}).get("acceptance_policy") or acceptance_policy(opts),
                "artifacts": {f: _sha(paths.REPO / f) for f in files}}
    hd.mkdir(parents=True, exist_ok=True)
    jsonl.write_atomic(hd / "manifest.json", json.dumps(manifest, indent=1, ensure_ascii=False))
    listed = files + [(hd / "manifest.json").relative_to(paths.REPO).as_posix(), (hd / "files.txt").relative_to(paths.REPO).as_posix()]
    jsonl.write_atomic(hd / "files.txt", "".join(f + "\n" for f in listed))
    return manifest


def _code_refusal(manifest: dict, now: dict) -> str:
    was = manifest.get("baseline", {}).get("code", {}).get("files", {})
    cur = now["files"]
    diff = sorted(k for k in set(was) | set(cur) if was.get(k) != cur.get(k))
    commit = manifest.get("baseline", {}).get("source_commit")
    return (f"the code that decides this run's results differs from its baseline ({len(diff)} file(s): {', '.join(diff[:8])}): "
            "a run continues only on the code it started on — start a new run id, or continue from a checkout of the run's "
            f"baseline{f' (commit {commit})' if commit else ''}")


def verify(run_id: str, artifacts: bool = True) -> tuple[list[str], list[str]]:
    """The checks before a machine continues a handed-over run: (refusals, warnings). Refused: no
    manifest; another run version than the one that started the run; other code than the run's
    baseline; other semantic inputs; saved options whose acceptance policy is not the one the run's
    first export recorded (`acceptance_policy_refusal`; a manifest without that anchor is warned
    `policy anchor missing: not verified`); with `artifacts`, a handed
    file missing or not the one exported; a lock or owner record in the run's directory. Warned: other
    Python or dependency versions than at the export."""
    from ..loop import semantic_inputs, run_version_refusal
    m = jsonl.read_json(paths.run_dir(run_id) / "handoff" / "manifest.json", None)
    if m is None:
        return [f"`{run_id}` has no handoff manifest"], []
    refusals, warnings = [], []
    version = run_version_refusal(m.get("semantic"))
    if version:
        refusals.append(f"the run was handed over by another run version: {version}")
    now = code_digest()
    if m.get("baseline", {}).get("code", {}).get("digest") != now["digest"]:
        refusals.append(_code_refusal(m, now))
    try:
        d = _options(run_id)                            # the run's options as saved, without restoring anything
        from ..store.state import Options
        fields = set(Options.__dataclass_fields__)
        kw = {k: v for k, v in d.items() if k in fields}
        for k in ("laws", "ontology", "definition_precedence", "model_prices"):
            if kw.get(k):
                kw[k] = paths.local(kw[k])
        kw["reading"] = paths.local(d.get("base_reading") or d["reading"])
        sem = semantic_inputs(Options(**kw))
        changed = sorted(k for k in set(sem) | set(m.get("semantic", {}))
                         if k != "run_version" and sem.get(k) != m.get("semantic", {}).get(k))
        if changed:
            refusals.append(f"the semantic inputs differ from the run's ({', '.join(changed)}): start a new run id")
        if m.get("acceptance_policy") is None:          # a manifest written before the anchor: read, never reported verified
            warnings.append("policy anchor missing: not verified (the manifest records no acceptance policy; the saved "
                            "options' policy is unchecked against the run's first export)")
        policy = acceptance_policy_refusal(m.get("acceptance_policy"), d)
        if policy:
            refusals.append(policy)
    except (OSError, KeyError, TypeError, ValueError) as e:
        refusals.append(f"the run's semantic inputs could not be read: {e}")
    if artifacts:
        miss = [f for f, h in (m.get("artifacts") or {}).items() if not (paths.REPO / f).is_file() or _sha(paths.REPO / f) != h]
        if miss:
            refusals.append(f"{len(miss)} handed file(s) missing or not as exported: {', '.join(miss[:8])}")
    stray = [p.name for p in paths.run_dir(run_id).rglob("*") if p.name in (".run.owner.json", ".run.lock")]
    if stray:
        refusals.append(f"the run's directory holds lock or owner files: {stray[:4]}")
    tc, was = toolchain(), m.get("toolchain", {})
    for k in ("python", "distributions", "lean"):
        if was.get(k) != tc.get(k):
            warnings.append(f"{k} differs from the export's ({was.get(k)} → {tc.get(k)})")
    return refusals, warnings


def check_on_launch(run) -> None:
    """At a loop start on a run that has a handoff manifest: the code and semantic checks always, and
    the handed files once per export on this checkout (`handoff/imported.json` records it); a refusal
    stops the launch before anything is rewritten."""
    hd = run.dir / "handoff"
    m = jsonl.read_json(hd / "manifest.json", None)
    if m is None:
        return
    seen = jsonl.read_json(hd / "imported.json", None) or {}
    first = seen.get("export_id") != m.get("export_id") or seen.get("root") != str(paths.REPO)
    refusals, warnings = verify(run.opts.run_id, artifacts=first)
    if refusals:
        raise SystemExit(f"[loop] the handed-over run `{run.opts.run_id}` cannot continue here — " + "; ".join(refusals)
                         + " — nothing of the run was rewritten")
    for w in warnings:
        print(f"[loop] handoff: {w}")
    if first:
        jsonl.write_atomic(hd / "imported.json", json.dumps({"export_id": m.get("export_id"), "root": str(paths.REPO),
                                                             "imported_at": time.strftime("%Y-%m-%dT%H:%M:%S"), "warnings": warnings}))
