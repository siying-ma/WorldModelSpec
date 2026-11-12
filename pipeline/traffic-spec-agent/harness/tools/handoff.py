"""The handoff of a run between machines: one machine writes the run at a time, and the state it hands
over is a self-contained checkpoint that the next machine verifies before it continues.

A run is pinned to the code that decides its results (`code_digest`: the harness, the recorded-data
code, the monitor and Explain sources, the prompts, Core with its root module, the ontology, the
configuration, the Lean build files, the region-kind exporter the harness runs, the doctor with the
modules it runs, the launcher, and the Python project file). The operator's
hints a session reads are pinned apart, in the run's directory (`Run.pin_hints`), and travel with it.
Every export carries the baseline the run's first export recorded, and every import and
every resume of a run that has a manifest refuses to continue on other code, other semantic inputs or
another acceptance policy than the run's first export recorded,
naming the files: a later development of the pipeline never changes a run's results. A checkpoint that
only adds run artifacts changes none of those files.

A run with a stage record (`stages.jsonl`) is pinned to its active stage instead: the code baseline,
the semantic inputs and the acceptance policy of the stage's `open` row, which only an explicit
transition replaces; its saved options keep what the run first recorded. Its manifest also names the
active stage (`stage_id`) and the stage record it was exported with (`stages_sha256`), and a checkpoint
of another stage, or of the same stage under another record, is refused. Nothing is exported or
verified while a transition is begun and not `done`, but the transition's own export of the stage it
opened.

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

from ..store import jsonl, paths, stages
from ..store.state import (READABLE_RUN_VERSIONS, acceptance_policy, acceptance_policy_refusal, policy_defects, run_version_refusal,
                           saved_version_refusal, snapshot_defects, stage_policy_refusal)

#: The files whose content decides a run's results, relative to the agent directory.
CODE_PATTERNS = ("harness/**/*.py", "recorded/**/*.py", "prompts/*", "ontology/*", "config/*",
                 "library/TrafficSpec/Core.lean", "library/TrafficSpec/Core/**/*.lean", "library/Explain.lean",
                 "library/Main.lean", "library/lean-toolchain", "library/lakefile.lean", "library/lake-manifest.json",
                 "scripts/RegionKinds.lean", "scripts/__init__.py", "scripts/diagnostics/*.py", "scripts/gen_ontology.py",
                 "scripts/run-generation.sh", "pyproject.toml")
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
    """What the run was built with besides its code: Python, the Lean toolchain as `lean --version`
    reports it and a digest of the installed distributions (no dependency is locked)."""
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


def checkpoint_problems(run_id: str, for_transition: bool = False) -> list[str]:
    """Why the run is not at a checkpoint another machine may take over (empty when it is). With
    `for_transition` (a stage transition, run on a checkout that already holds the next stage's code,
    or the export of a run with a stage record, whose code the export pins to its active stage's),
    the library's code files (`code_files`: Core, Explain, Main, the build files) are left out of the
    freeze comparison: a change there is the transition's, judged by its file classification. Every
    other file of the freeze (rules, concepts, witnesses, readings, the run's reading and state) is
    still compared, and the run's handed files are still checked against its last export by `verify`."""
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
    if snap is not None and snapshot_defects(snap, run_id):     # the test a resume applies to the snapshot it restores
        return bad + ["its snapshot state.json is not whole (" + "; ".join(snapshot_defects(snap, run_id)[:6]) + ")"]
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
    if for_transition:
        lib = paths.LIBRARY.resolve()
        code = {p.resolve().relative_to(lib).as_posix() for p in code_files() if p.resolve().is_relative_to(lib)}
        f = rd / "frozen" / "manifest.json"
        if not f.exists():
            bad += [f"freeze: {x}" for x in label_check.drift(rd)[:6]]
        else:
            was = {k: v for k, v in json.loads(f.read_text(encoding="utf-8")).items() if k not in code}
            now = {k: v for k, v in label_check.frozen_manifest(rd).items() if k not in code}
            bad += [f"freeze: {k} differs from the freeze" for k in sorted(set(was) | set(now)) if was.get(k) != now.get(k)][:6]
    else:
        bad += [f"freeze: {x}" for x in label_check.drift(rd)[:6]]
    return bad


def active_stage(rd: Path) -> tuple[dict | None, str | None]:
    """The `open` row of the run's active stage (None without a stage record) and why the run may not
    continue on it (None when it may): a record that cannot be read whole, or a stage whose files are of
    a state schema this harness does not read."""
    try:
        stage = stages.active_stage(rd)
    except jsonl.DataIntegrityError as e:
        return None, f"its stage record cannot be read whole ({e})"
    if stage is not None and not any(stage.get("state_schema") == v for v in READABLE_RUN_VERSIONS):
        return stage, (f"its active stage `{stage.get('stage_id')}` records the state schema {stage.get('state_schema')!r}, which this "
                       f"harness does not read (it reads {sorted(READABLE_RUN_VERSIONS)})")
    return stage, None


def transition_refusal(rd: Path, transition: str | None = None) -> str | None:
    """Why nothing may run on the run while a transition is begun and not `done` (`stages.transition_refusal`),
    or None. The transition named `transition`, once `applied`, may export the stage it opened."""
    why = stages.transition_refusal(rd)
    if why is None:
        return None if transition is None else f"no stage transition `{transition}` is in progress"
    st = stages.transition_state(rd) or {}
    if transition is not None and st.get("transition_id") == transition and st.get("status") == "applied":
        return None
    return why


def export(run_id: str, source_baseline: str = "", transition: str | None = None) -> dict:
    """Write the handoff of a run at a checkpoint (see the module's description); refuses otherwise.
    Returns the manifest. A run another run version started is refused on its raw saved version
    before the library is taken or anything is written; so is a run in the middle of a stage
    transition, unless `transition` names that transition and it is `applied` (the transition's own
    export of the stage it opened). With a stage record the manifest carries the active stage's
    baseline, semantic inputs and policy, its id and the record's digest."""
    from ..store import owner
    rd = paths.run_dir(run_id)
    if (rd / "options.json").exists():
        why = saved_version_refusal(rd)
        if why:
            raise SystemExit(f"[handoff] `{run_id}` cannot be exported by this harness: {why} — nothing was written")
    why = transition_refusal(rd, transition)
    if why:
        raise SystemExit(f"[handoff] `{run_id}` cannot be exported: {why} — nothing was written")
    stage, why = active_stage(rd)
    if why:
        raise SystemExit(f"[handoff] `{run_id}` cannot be exported: {why} — nothing was written")
    if not owner.holds():                               # a command that owns the library already (a stage transition) exports as itself
        if transition:                                   # a transition's own export: that transition and no other goes on
            owner.acquire_for_transition(run_id, transition)
        else:
            owner.acquire_for_command("handoff")         # the single writer
    # a staged run's code is pinned to its active stage's baseline below, and its freeze holds the code of the
    # stage that wrote it, which after a transition is the stage before: the library's code is left to the pin
    bad = checkpoint_problems(run_id, for_transition=stage is not None)
    if bad:
        raise SystemExit(f"[handoff] `{run_id}` is not at a checkpoint: " + "; ".join(bad))
    opts = _options(run_id)
    hd = rd / "handoff"
    was = jsonl.read_json(hd / "manifest.json", None)
    code = code_digest()
    if stage is not None:
        return _export_stage(run_id, rd, opts, stage, code, was, source_baseline)
    if was is not None and was.get("baseline", {}).get("code", {}).get("digest") != code["digest"]:
        raise SystemExit("[handoff] " + _code_refusal(was, code))
    anchor = (was or {}).get("acceptance_policy")
    # the policy the manifest records is whole and is the saved options' own, never one completed by a default; a
    # manifest that records none has lost its anchor, which no later export writes again from the options
    policy = ("the run's handoff manifest records no acceptance policy" if was is not None and anchor is None
              else acceptance_policy_refusal(anchor, opts) if anchor is not None
              else "; ".join(policy_defects(acceptance_policy(opts))) or None)
    if policy:
        raise SystemExit(f"[handoff] `{run_id}`'s acceptance policy cannot be handed over: {policy} — nothing was written")
    snap = jsonl.read_json(rd / "state.json", {}) or {}
    summary = jsonl.read_json(rd / "summary.json", {}) or {}
    files = artifact_files(run_id)
    manifest = {"export_id": uuid.uuid4().hex, "run": run_id, "exported_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
                "iteration": snap.get("iteration"), "stage": (snap.get("prog") or {}).get("stage"),
                "status": summary.get("status"), "stop": summary.get("stop"), "pending": summary.get("pending"),
                "repo_root": str(paths.REPO),
                "baseline": (was or {}).get("baseline") or {"source_commit": source_baseline or None, "code": code},
                "toolchain": toolchain(), "semantic": opts.get("semantic", {}),
                "acceptance_policy": anchor if anchor is not None else acceptance_policy(opts),
                "artifacts": {f: _sha(paths.REPO / f) for f in files}}
    _write(hd, manifest, files)
    return manifest


def _write(hd: Path, manifest: dict, files: list[str]) -> None:
    hd.mkdir(parents=True, exist_ok=True)
    jsonl.write_atomic(hd / "manifest.json", json.dumps(manifest, indent=1, ensure_ascii=False))
    listed = files + [(hd / "manifest.json").relative_to(paths.REPO).as_posix(), (hd / "files.txt").relative_to(paths.REPO).as_posix()]
    jsonl.write_atomic(hd / "files.txt", "".join(f + "\n" for f in listed))


def _export_stage(run_id: str, rd: Path, opts: dict, stage: dict, code: dict, was: dict | None, source_baseline: str) -> dict:
    """The export of a run with a stage record: on the active stage's code, with its policy as the
    saved options hold it; the manifest's baseline, semantic inputs and policy are the stage's own.
    The baseline's commit is the one the stage records; a stage that records none (a run started
    without `--source_commit`) takes the commit its first export was given (`source_baseline`), kept
    by every later export of the stage, as a run without a stage record keeps its first export's."""
    base = stage.get("code_baseline") or {}
    commit = base.get("source_commit")
    if commit is None:
        same = was is not None and was.get("stage_id") == stage.get("stage_id")
        commit = ((was.get("baseline") or {}).get("source_commit") if same else None) or source_baseline or None
    if base.get("code", {}).get("digest") != code["digest"]:
        raise SystemExit("[handoff] " + _code_refusal({"baseline": base}, code, stage.get("stage_id")))
    policy = stage_policy_refusal(stage, opts)
    if policy:
        raise SystemExit(f"[handoff] `{run_id}`'s acceptance policy cannot be handed over: {policy} — nothing was written")
    snap = jsonl.read_json(rd / "state.json", {}) or {}
    summary = jsonl.read_json(rd / "summary.json", {}) or {}
    files = artifact_files(run_id)
    manifest = {"export_id": uuid.uuid4().hex, "run": run_id, "exported_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
                "iteration": snap.get("iteration"), "stage": (snap.get("prog") or {}).get("stage"),
                "status": summary.get("status"), "stop": summary.get("stop"), "pending": summary.get("pending"),
                "repo_root": str(paths.REPO), "baseline": {**base, "source_commit": commit}, "toolchain": toolchain(),
                "semantic": stage.get("semantic") or {},
                "acceptance_policy": stage["acceptance_policy"], "stage_id": stage["stage_id"],
                "stages_sha256": stages.stages_sha256(rd), "artifacts": {f: _sha(paths.REPO / f) for f in files}}
    _write(rd / "handoff", manifest, files)
    return manifest


def _code_refusal(manifest: dict, now: dict, stage_id: str | None = None) -> str:
    was = manifest.get("baseline", {}).get("code", {}).get("files", {})
    cur = now["files"]
    diff = sorted(k for k in set(was) | set(cur) if was.get(k) != cur.get(k))
    commit = manifest.get("baseline", {}).get("source_commit")
    if stage_id is not None:
        return (f"the code that decides this run's results differs from the baseline of its active stage `{stage_id}` ({len(diff)} "
                f"file(s): {', '.join(diff[:8])}): a run continues only on its active stage's code, and other code only through a "
                f"stage transition — continue from a checkout of the stage's baseline{f' (commit {commit})' if commit else ''}")
    return (f"the code that decides this run's results differs from its baseline ({len(diff)} file(s): {', '.join(diff[:8])}): "
            "a run continues only on the code it started on — start a new run id, or continue from a checkout of the run's "
            f"baseline{f' (commit {commit})' if commit else ''}")


def verify(run_id: str, artifacts: bool = True, for_transition: bool = False) -> tuple[list[str], list[str]]:
    """The checks before a machine continues a handed-over run: (refusals, warnings). Refused: no
    manifest; another run version than the one that started the run (the manifest's, or the saved
    options' read raw); other code than the run's
    baseline; other semantic inputs; saved options whose acceptance policy is not the one the run's
    first export recorded (`acceptance_policy_refusal`), or a manifest without that anchor; a snapshot
    a resume would not restore (`snapshot_defects`);
    with `artifacts`, a handed file missing or not the one exported; a lock or owner record in the
    run's directory. Warned: other
    Python or dependency versions than at the export. No base chain is checked: `export` refuses a
    run with a `base_run`, so a handed-over run has none.

    With a stage record, the code, semantic inputs and policy are those of the active stage's `open`
    row, and a manifest of another stage, or one whose `stages_sha256` is not the record on disk, is
    refused. A transition begun and not `done` refuses every verification.

    `for_transition` is the check a transition makes of the checkpoint of the stage it closes: it is
    made from a checkout that already holds the next stage's code, so the comparisons of this tree's
    code, semantic inputs and policy with the stage (which describe the next stage, not the one
    closing) are left out; every check of the checkpoint itself is kept: the handed files present and
    as exported, the snapshot, lock files, and the manifest's stage and stage record."""
    rd = paths.run_dir(run_id)
    why = stages.transition_refusal(rd)
    if why:
        return [why], []
    m = jsonl.read_json(rd / "handoff" / "manifest.json", None)
    if m is None:
        return [f"`{run_id}` has no handoff manifest"], []
    refusals, warnings = [], []
    stage, why = active_stage(rd)
    if why:
        refusals.append(f"the run {why}")
    if stage is not None:
        if m.get("stage_id") != stage.get("stage_id"):
            refusals.append(f"the manifest is a checkpoint of stage {m.get('stage_id')!r}, not of the active stage "
                            f"`{stage.get('stage_id')}`: restore the active stage's checkpoint")
        if m.get("stages_sha256") != stages.stages_sha256(rd):
            refusals.append("the manifest was exported with another stage record than the run's stages.jsonl: a checkpoint "
                            "never replaces a newer stage record — restore the checkpoint of the record on disk")
    elif m.get("stage_id") is not None and not why:
        refusals.append(f"the manifest is a checkpoint of stage `{m.get('stage_id')}`, and the run has no stage record")
    version = run_version_refusal(m.get("semantic"))
    if version:
        refusals.append(f"the run was handed over by another run version: {version}")
    saved = saved_version_refusal(paths.run_dir(run_id))
    if saved:
        refusals.append(f"the run's saved options are of another run version: {saved}")
    if not for_transition:
        refusals += _pinned_refusals(run_id, m, stage)
    if artifacts:
        miss = [f for f, h in (m.get("artifacts") or {}).items() if not (paths.REPO / f).is_file() or _sha(paths.REPO / f) != h]
        if miss:
            refusals.append(f"{len(miss)} handed file(s) missing or not as exported: {', '.join(miss[:8])}")
    try:                                                # read raw, never through `Run.load`, which restores it
        snap = jsonl.read_json(paths.run_dir(run_id) / "state.json", None)
        bad = ["it is missing"] if snap is None else snapshot_defects(snap, run_id)
    except jsonl.DataIntegrityError as e:
        bad = [f"it cannot be read ({e})"]
    if bad:
        refusals.append("the run's snapshot state.json is not one a resume restores (" + "; ".join(bad[:6]) + ")")
    stray = [p.name for p in paths.run_dir(run_id).rglob("*") if p.name in (".run.owner.json", ".run.lock")]
    if stray:
        refusals.append(f"the run's directory holds lock or owner files: {stray[:4]}")
    tc, was = toolchain(), m.get("toolchain", {})
    for k in ("python", "distributions", "lean"):
        if was.get(k) != tc.get(k):
            warnings.append(f"{k} differs from the export's ({was.get(k)} → {tc.get(k)})")
    return refusals, warnings


def _pinned_refusals(run_id: str, m: dict, stage: dict | None) -> list[str]:
    """Why this checkout may not continue the run on its pins: this tree's code, semantic inputs and the
    saved options' policy against the manifest's (a run without a stage record) or the active stage's."""
    from ..loop import semantic_inputs
    refusals = []
    now = code_digest()
    pin = m if stage is None else {"baseline": stage.get("code_baseline") or {}}
    if pin.get("baseline", {}).get("code", {}).get("digest") != now["digest"]:
        refusals.append(_code_refusal(pin, now, None if stage is None else stage.get("stage_id")))
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
        fixed = m.get("semantic", {}) if stage is None else stage.get("semantic") or {}
        changed = sorted(k for k in set(sem) | set(fixed) if k != "run_version" and sem.get(k) != fixed.get(k))
        if changed and stage is not None:
            refusals.append(f"the semantic inputs differ from those of the active stage `{stage.get('stage_id')}` "
                            f"({', '.join(changed)}): other inputs are entered only through a stage transition")
        elif changed:
            refusals.append(f"the semantic inputs differ from the run's ({', '.join(changed)}): start a new run id")
        if stage is not None:
            policy = stage_policy_refusal(stage, d)
            if policy:
                refusals.append(policy)
        elif m.get("acceptance_policy") is None:        # never completed from the saved options: the export's record is the anchor
            refusals.append("the manifest records no acceptance policy, so the saved options' policy cannot be checked against "
                            "the run's first export: re-export the run from its checkpoint")
        else:
            policy = acceptance_policy_refusal(m.get("acceptance_policy"), d)
            if policy:
                refusals.append(policy)
    except (OSError, KeyError, TypeError, ValueError) as e:
        refusals.append(f"the run's semantic inputs could not be read: {e}")
    return refusals


def check_on_launch(run) -> None:
    """At a loop start on a run that has a handoff manifest: the code and semantic checks always, and
    the handed files once per export on this checkout (`handoff/imported.json` records it); a refusal
    stops the launch before anything is rewritten. A transition begun and not `done` refuses the launch;
    a run with a stage record and no manifest yet is checked on its active stage's code."""
    why = stages.transition_refusal(run.dir)
    if why:
        raise SystemExit(f"[loop] run `{run.opts.run_id}` cannot continue here — {why} — nothing of the run was rewritten")
    hd = run.dir / "handoff"
    m = jsonl.read_json(hd / "manifest.json", None)
    if m is None:                                       # never handed over: a staged run is still held to its stage's code
        stage, why = active_stage(run.dir)
        if why is None and stage is not None:
            now = code_digest()
            base = stage.get("code_baseline") or {}
            if base.get("code", {}).get("digest") != now["digest"]:
                why = _code_refusal({"baseline": base}, now, stage.get("stage_id"))
        if why:
            raise SystemExit(f"[loop] run `{run.opts.run_id}` cannot continue here — {why} — nothing of the run was rewritten")
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
