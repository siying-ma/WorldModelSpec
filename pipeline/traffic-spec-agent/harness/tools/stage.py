"""The stage transitions of a run: the only way a run's code baseline changes, and the commands that
read and restore a closed stage.

`enter` closes the active stage and opens the next one on the code of this checkout. It refuses,
before it writes anything, unless the transition is allowed (`stages.ALLOWED_TRANSITIONS`; a review
stage is refused outright, and a labels stage is entered from a review stage only), this process
owns the library, the run is at a checkpoint another machine may take over
(`handoff.checkpoint_problems`), the active stage and the handoff manifest's stage are the stage
named as `--from`, the files on disk are those of the last export (`handoff.verify` for a
transition), no label repair is active and no concept review deferred, no other transition is in
progress or has left the same stage, generation is complete for the laws the new stage covers when
a generation stage closes, and every code file that changed since the closing stage's baseline
belongs to an allowed class:

- forbidden: Core, the ontology, the definition precedence and its resolver, the Lean toolchain and
  build files, the region-kind exporter, the split tools, the ontology generator, and the concept
  review and aggregate verifier with their prompts; with the run's comparison set fixed
  (`comparison_set.json`), any file that changes the scoring digest (`label_check.scoring_version`);
- generated text: `prompts/*.md`, or any harness module while the generated prompt text the code
  renders changed; allowed only with `--prompts-approved` equal to `prompts_digest` of the new
  semantic inputs;
- gate: the gate's modules (`integrate.GATE_SOURCES`), re-gated by their admission keys at the next
  launch;
- scoring: the scoring files while the comparison set is not fixed yet;
- tool: the launcher, the stage commands and record, the handoff and the doctor.

What a file does decides its class before where it lies: a gate or tool module counts as generated
text while the generated prompt text changed, and a scoring file is forbidden while the comparison set
is fixed. Any other changed file is refused, and so is a change of any semantic input but the prompts
and their generated text. The new stage covers the laws of the closing stage's scope; a `--scope`
only widens it, each added law generated.

A transition is one transaction. The closing stage's snapshot is written first (`snapshot.write`) and
verified; then `stage_transition.json` records the transition `prepared` with the two rows it
appends; then a journal holding the replacement of `stages.jsonl` and of the transition record
(`stages.JOURNAL_FILE`) is written under the library's pending pointer, the candidate commit's own
mechanism: the journal is the commit point, and the next owner of the library completes a committed
journal before anything reads the library (`candidate.recover_pending`). Applied, the run is exported
as the new stage (`handoff.export`), the record says `exported`, and the launcher commits and pushes
the run branch; `confirm` checks that commit on the remote branch and records `done`. Until then every
launch is refused, and running the same transition again continues from the recorded state and
reports success only after the stage record, the manifest and (once confirmed) the commit agree.

`adopt` registers a run made before stages existed as its first stage `G0`, in a new checkout, after
checking the old checkout independently: its own code's `handoff verify`, every code file of the old
manifest hashed again under it, and its git history from the run's source commit. The G0 manifest is
the old one with the stage's id, the stage record's digest and the record among its artifacts.

Every `open` row this module writes records the closing-stage effects the next transition compares
(`effects`: the gate digest, the scoring digest, and the generated and written prompt digests)."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
import uuid
from pathlib import Path

from ..store import jsonl, owner, paths, snapshot, stages
from ..store.state import RUN_VERSION
from . import handoff

#: Files no transition may change: the meaning of every record rests on them.
FORBIDDEN_FILES = frozenset({
    "library/TrafficSpec/Core.lean", "config/definition_precedence.json", "harness/model/definitions.py",
    "library/lean-toolchain", "library/lakefile.lean", "library/lake-manifest.json", "scripts/RegionKinds.lean",
    "harness/tools/split.py", "scripts/gen_ontology.py", handoff.DOCTOR_TOOL,
    "harness/phases/review.py", "prompts/review_concept.md", "prompts/adjudicate_concept.md", "prompts/recheck_concept.md",
    "harness/phases/aggregate.py", "harness/checks/aggregates.py", "prompts/verify_aggregate.md"})
FORBIDDEN_DIRS = ("library/TrafficSpec/Core/", "ontology/")
#: The files `label_check.scoring_version` digests, by name and content, in its order.
SCORING_FILES = ("recorded/scoring.py", "recorded/labels.py", "harness/phases/label_check.py", "library/Explain.lean")
#: The launcher, the stage commands and record, the handoff and the doctor: recorded file by file. The
#: harness's entry point is not one: it parses every launch's options, so a change there is unclassified.
TOOL_FILES = frozenset({"scripts/run-generation.sh", "harness/tools/stage.py", "harness/store/stages.py",
                        "harness/store/snapshot.py", "harness/tools/handoff.py", "scripts/__init__.py"})
TOOL_DIRS = ("scripts/diagnostics/",)
#: The semantic inputs a transition may change (with the operator's approval of the prompts).
CHANGEABLE_SEMANTIC = ("prompts", "generated_prompts", "run_version")
#: Where a transition stages the files its journal replaces.
STAGING = "transitions"


def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def _now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%S")


def _refuse(what: str, why) -> SystemExit:
    why = [why] if isinstance(why, str) else list(why)
    return SystemExit(f"[stage] {what} refused: " + "; ".join(why) + " — nothing was written")


# -- effects ---------------------------------------------------------------------------------------

def gate_digest_at(root: Path) -> str:
    """`integrate.gate_digest` computed over the gate's modules under `root`."""
    from ..phases import integrate
    files = []
    for rel in integrate.GATE_SOURCES:
        p = root / rel
        files += sorted(p.rglob("*.py")) if p.is_dir() else [p]
    return integrate._digest({str(f.relative_to(root)): f.read_text(encoding="utf-8") for f in files if f.exists()})[:24]


def scoring_version_at(root: Path) -> str:
    """`label_check.scoring_version` computed over the scoring files under `root`."""
    h = hashlib.sha256()
    for rel in SCORING_FILES:
        f = root / rel
        h.update(f.name.encode()); h.update(f.read_bytes() if f.is_file() else b"(missing)")
    return h.hexdigest()


def effects_at(root: Path, semantic: dict) -> dict:
    """What a code baseline at `root` does that a transition compares: the gate and scoring digests
    of its files, and the written and generated prompt digests of its semantic inputs."""
    return {"gate": gate_digest_at(root), "scoring": scoring_version_at(root),
            "generated_prompts": semantic.get("generated_prompts"), "prompts": semantic.get("prompts")}


def prompts_digest(semantic: dict) -> str:
    """The digest an operator approves for a change of the prompts: the written prompts' digest and
    the generated prompt text's, together."""
    return hashlib.sha256(json.dumps({"prompts": semantic.get("prompts"), "generated_prompts": semantic.get("generated_prompts")},
                                     sort_keys=True).encode()).hexdigest()


# -- the classification of a code change -----------------------------------------------------------

def _in(path: str, files, dirs) -> bool:
    return path in files or any(path.startswith(d) for d in dirs)


def classify(was_files: dict, now_files: dict, was: dict, now: dict, comparison_fixed: bool) -> list[dict]:
    """Every code file that differs between two baselines (`{path: sha256}`, a file present on one
    side only included) with its class: `forbidden`, `unclassified` (refused by default),
    `generated_text`, `gate`, `scoring` or `tool`. `was` and `now` are the two baselines' effects."""
    from ..phases import integrate
    gate_dirs = tuple(g.rstrip("/") + "/" for g in integrate.GATE_SOURCES)
    scoring_moved = was.get("scoring") != now.get("scoring")
    generated_moved = was.get("generated_prompts") != now.get("generated_prompts")
    out = []
    for p in sorted(k for k in set(was_files) | set(now_files) if was_files.get(k) != now_files.get(k)):
        if _in(p, FORBIDDEN_FILES, FORBIDDEN_DIRS):
            cls = "forbidden"
        elif p in SCORING_FILES:
            cls = "forbidden" if comparison_fixed and scoring_moved else "scoring"
        elif p.startswith("prompts/") and p.endswith(".md"):
            cls = "generated_text"
        else:
            base = "gate" if _in(p, set(integrate.GATE_SOURCES), gate_dirs) else "tool" if _in(p, TOOL_FILES, TOOL_DIRS) else None
            cls = ("generated_text" if base and generated_moved and p.endswith(".py")     # what it renders, before where it lies
                   else base or "unclassified")
        out.append({"path": p, "class": cls})
    if comparison_fixed and scoring_moved and not any(c["path"] in SCORING_FILES for c in out):
        out.append({"path": "(scoring digest)", "class": "forbidden"})
    return out


def change_refusals(changed: list[dict], was_sem: dict, now_sem: dict, approved: str | None) -> list[str]:
    """Why a classified change may not be entered: a forbidden or unclassified file, a semantic input
    outside the prompts changed, or prompts changed without the operator's approval of their digest."""
    bad = []
    forb = [c["path"] for c in changed if c["class"] == "forbidden"]
    if forb:
        bad.append(f"{len(forb)} changed file(s) no transition may change: {', '.join(forb[:8])} — start a new run id")
    unk = [c["path"] for c in changed if c["class"] == "unclassified"]
    if unk:
        bad.append(f"{len(unk)} changed file(s) in no class a transition allows: {', '.join(unk[:8])}")
    sem = sorted(k for k in set(was_sem) | set(now_sem) if k not in CHANGEABLE_SEMANTIC and was_sem.get(k) != now_sem.get(k))
    if sem:
        bad.append(f"the semantic inputs differ from the stage's ({', '.join(sem)}): start a new run id")
    need = any(was_sem.get(k) != now_sem.get(k) for k in ("prompts", "generated_prompts"))
    want = prompts_digest(now_sem)
    if (need or approved) and approved != want:
        bad.append(f"the prompts or their generated text changed: give --prompts-approved {want} once the operator approved them"
                   if not approved else f"--prompts-approved {approved} is not the digest of these prompts ({want})")
    return bad


# -- reading the run -------------------------------------------------------------------------------

def _options(run_id: str):
    """The run's options as saved, read without restoring or rewriting anything."""
    from ..store.state import Options
    d = handoff._options(run_id)
    kw = {k: v for k, v in d.items() if k in Options.__dataclass_fields__}
    for k in ("laws", "ontology", "definition_precedence", "model_prices"):
        if kw.get(k):
            kw[k] = paths.local(kw[k])
    kw["reading"] = paths.local(d.get("base_reading") or d["reading"])
    return Options(**kw)


def _generation(run_id: str) -> dict:
    """The run's `generation_report`, computed from its state now."""
    from ..phases import feedback
    from ..store.ledger import Ledger
    from ..store.state import Run
    run = Run.load(run_id)
    ledger = Ledger(run.ledger_file, [], run.opts.plan_attempts)
    return feedback.generation_report(run, ledger)


def _read_scope(arg: str) -> list[str]:
    f = Path(arg)
    text = f.read_text(encoding="utf-8")
    laws = json.loads(text) if text.lstrip().startswith("[") else [x.strip() for x in text.splitlines() if x.strip()]
    if not laws or not all(isinstance(x, str) and x for x in laws):
        raise _refuse("stage enter", f"the scope file {arg} lists no law ids")
    return sorted(set(laws))


def scope_value(laws: list[str]) -> dict:
    """A scope that is not every law: its laws, their digest, and `partial`, so a stage record and every
    report built from it say that the stage covers part of the run."""
    return {"laws": sorted(laws), "sha256": hashlib.sha256(json.dumps(sorted(laws)).encode()).hexdigest(), "partial": True}


def _unfinished(report: dict, laws=None) -> str:
    out = []
    for k, v in (report.get("laws") or {}).items():
        if k == "generated":
            continue
        ids = [x for x in (v if isinstance(v, list) else list(v)) if laws is None or x in laws]
        if ids:
            out.append(f"{k}: {', '.join(sorted(ids)[:8])}")
    return "; ".join(out) or "none listed"


def new_scope(run_id: str, active: dict, to_kind: str, arg: str | None) -> tuple[object, list[str]]:
    """The new stage's scope and the refusals.

    - Entering review from generation is the one point where the scope may first be chosen: every law
      (`all`, which needs generation complete) or a list of generated laws (a partial review). A scope
      already a list there is only widened.
    - Replacing a stage's code (generation → generation, labels → labels) keeps its scope as it is and
      asks nothing of generation: no `arg` is taken there except a widening of a list into a larger
      list or `all`, in a stage after generation, every added law generated.
    - A scope is never narrowed. A report that cannot be computed refuses."""
    from_kind = active.get("stage_kind")
    prev = active.get("scope", "all")
    prev_laws = None if prev in (None, "all") else set(prev["laws"])
    first_choice = from_kind == "generation" and to_kind == "review"
    if arg is None:
        new = prev if prev is not None else "all"
    elif arg == "all":
        new = "all"
    else:
        new = scope_value(_read_scope(arg))
    new_laws = None if new == "all" else set(new["laws"])
    if prev_laws is None and new_laws is not None and not first_choice:
        return new, ["the scope `all` is narrowed only when generation is left for review: a scope is otherwise only widened"]
    if prev_laws is not None and new_laws is not None and not prev_laws <= new_laws:
        return new, [f"the new scope leaves out laws of the stage's scope ({', '.join(sorted(prev_laws - new_laws)[:8])}): "
                     "a scope is only widened"]
    widened = new_laws != prev_laws and not (prev_laws is None and new_laws is None)
    if from_kind == "generation" and to_kind == "generation":
        if arg is not None:                               # not even the scope it already has: none is taken here
            return new, ["a generation stage's code is replaced with its scope as it is: no scope is given here"]
        return new, []
    if not first_choice and not widened:
        return new, []
    report = _generation(run_id)
    if report.get("complete") is None:
        return new, [f"whether generation is complete cannot be read: {report.get('reason_if_null')}"]
    generated = set((report.get("laws") or {}).get("generated", []))
    if new_laws is None:
        if report.get("complete") is not True:
            return new, ["generation is not complete (" + _unfinished(report) + "): give --scope with laws all generated"]
        return new, []
    check = new_laws if first_choice and prev_laws is None else new_laws - (prev_laws or set())
    missing = sorted(check - generated)
    if missing:
        return new, [f"law(s) of the scope not generated: {', '.join(missing[:8])} (" + _unfinished(report, set(missing)) + ")"]
    return new, []


# -- the transaction -------------------------------------------------------------------------------

def _rows_text(rows: list[dict]) -> str:
    return "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows)


def _finish_journal(rd: Path) -> None:
    """A transaction a stopped owner committed is completed, as the library's next owner does, and a
    pointer left short of its commit point is removed."""
    from ..phases import candidate
    candidate.recover_pending()
    j = jsonl.read_json(rd / stages.JOURNAL_FILE, None)
    if j is not None and j.get("status") == "committed":
        candidate._apply(j, rd / stages.JOURNAL_FILE)


def _commit(rd: Path, record: dict, extra: list[tuple[bytes, Path]] = ()) -> None:
    """Write the transition's journal (the commit point) and apply it: the stage record with the
    transition's rows appended, the transition record as `applied`, and any `extra` (content, path)."""
    from ..phases import candidate
    t = record["transition_id"]
    area = rd / stages.STAGES_DIR / STAGING / t
    if area.exists():
        shutil.rmtree(area)
    area.mkdir(parents=True)
    f = rd / stages.STAGES_FILE
    was = f.read_bytes() if f.is_file() else b""
    if was and not was.endswith(b"\n"):
        was += b"\n"
    puts = [(was + _rows_text(record["rows"]).encode(), f),
            (json.dumps({**record, "status": "applied"}, ensure_ascii=False, indent=1).encode(), rd / stages.TRANSITION_FILE), *extra]
    ops = []
    for i, (data, to) in enumerate(puts):
        src = area / f"{i:02d}-{to.name}"
        with open(src, "wb") as fh:
            fh.write(data); fh.flush(); os.fsync(fh.fileno())
        ops.append({"put": str(src), "to": str(to)})
    journal = {"candidate": f"stage transition {t}", "area": str(area), "status": "committed", "ops": ops,
               "run_id": record["run_id"], "transition_id": t}
    jsonl.write_atomic(candidate.pending_file(), json.dumps({"journal": str(rd / stages.JOURNAL_FILE)}))
    jsonl.write_atomic(rd / stages.JOURNAL_FILE, json.dumps(journal, ensure_ascii=False, indent=1))      # the commit point
    candidate._apply(journal, rd / stages.JOURNAL_FILE)


def _set_status(rd: Path, record: dict, status: str, **fields) -> dict:
    record = {**record, **fields, "status": status, f"{status}_at": _now()}
    jsonl.write_atomic(rd / stages.TRANSITION_FILE, json.dumps(record, ensure_ascii=False, indent=1))
    return record


def _export(run_id: str, rd: Path, record: dict) -> dict:
    """Export the run as the transition's new stage and record it `exported`."""
    m = handoff.export(run_id, transition=record["transition_id"])
    bad = _agreement(rd, record, exported=False)
    if bad:
        raise SystemExit(f"[stage] the export of `{run_id}` does not agree with the transition: " + "; ".join(bad))
    return _set_status(rd, record, "exported", export_id=m.get("export_id"),
                       manifest_sha256=_sha(rd / "handoff" / "manifest.json"), stages_sha256=stages.stages_sha256(rd))


def _agreement(rd: Path, record: dict, exported: bool = True) -> list[str]:
    """How the run disagrees with a transition that reached its export: the stage record holds its
    rows as planned, the manifest names its new stage and the record's digest; with `exported`, the
    record's digest is the one exported."""
    bad = []
    rows = stages.read_stages(rd)
    want = record["rows"]
    if not all(r in rows for r in want):
        bad.append("stages.jsonl does not hold the transition's rows")
    m = jsonl.read_json(rd / "handoff" / "manifest.json", None) or {}
    if m.get("stage_id") != record["to"]:
        bad.append(f"the handoff manifest names the stage `{m.get('stage_id')}`, not `{record['to']}`")
    if m.get("stages_sha256") != stages.stages_sha256(rd):
        bad.append("the handoff manifest's stages_sha256 is not the stage record's")
    if exported and record.get("stages_sha256") != stages.stages_sha256(rd):
        bad.append("the stage record changed since the transition's export")
    return bad


def _next_id(rows: list[dict], kind: str) -> str:
    letter = kind[0].upper()
    nums = [int(r["stage_id"][1:]) for r in rows if r.get("event") == "open" and r["stage_id"][:1] == letter
            and r["stage_id"][1:].isdigit()]
    return f"{letter}{max(nums) + 1 if nums else 0}"


def _head(root: Path) -> str | None:
    p = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"], capture_output=True, text=True)
    return p.stdout.strip() if p.returncode == 0 else None


def baseline_refusal(root: Path, commit: str | None, files: dict) -> str | None:
    """Why `commit` cannot be recorded as the baseline of a stage whose code is `files` (paths relative
    to `root`, the agent directory): it is no commit of the checkout, or the checkout's code differs from
    it (a code file changed, removed or added and not committed), so a clean checkout of it would not
    hold the stage's code and the stage could not be restored there. A path outside the checkout's
    repository (the doctor's split tool, outside a checkout of the agent directory alone) is not judged."""
    if not commit:
        return "the new stage's baseline commit cannot be read (this checkout is no git checkout): give --source_commit"
    if subprocess.run(["git", "-C", str(root), "cat-file", "-e", f"{commit}^{{commit}}"], capture_output=True).returncode != 0:
        return f"the baseline commit {commit} is not a commit of this checkout"
    top = subprocess.run(["git", "-C", str(root), "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()
    inside = [f for f in files if top and (root / f).resolve().is_relative_to(Path(top).resolve())]
    if not inside:
        return None
    diff = subprocess.run(["git", "-C", str(root), "diff", "--name-only", commit, "--", *inside], capture_output=True, text=True)
    new = subprocess.run(["git", "-C", str(root), "ls-files", "--others", "--exclude-standard", "--", *inside],
                         capture_output=True, text=True)
    differ = sorted(set(diff.stdout.split()) | set(new.stdout.split()))
    if diff.returncode != 0 or differ:
        return (f"this checkout's code differs from the baseline commit {commit} ({', '.join(differ[:8]) or diff.stderr.strip()[:200]}): "
                "commit the new code and give that commit as --source_commit, so the stage can be restored from it")
    return None


def _continue(run_id: str, rd: Path, record: dict) -> dict:
    """Carry a transition on from its recorded state to `exported` (an adoption's own export is its
    journal), or check one already exported or done."""
    status = record.get("status")
    if status == "prepared":
        if record["action"] == "adopt":
            raise SystemExit("[stage] an adoption stopped before its commit point is begun again with `stage adopt`")
        bad = []
        active = stages.active_stage(rd)
        if (active or {}).get("stage_id") != record["from"]:
            bad.append(f"the active stage is `{(active or {}).get('stage_id')}`, not `{record['from']}`")
        code = handoff.code_digest()
        if code["digest"] != record["rows"][1]["code_baseline"]["code"]["digest"]:
            bad.append("the code of this checkout changed since the transition was prepared")
        m = jsonl.read_json(rd / "handoff" / "manifest.json", None) or {}
        if m.get("export_id") != record["rows"][0]["output_checkpoint"]["export_id"]:
            bad.append("the run was exported again since the transition was prepared")
        bad += snapshot.verify(run_id, record["from"])
        if bad:
            raise _refuse(f"continuing the transition `{record['transition_id']}`", bad)
        _commit(rd, record)
        record = stages.transition_state(rd)
        status = record["status"]
    if status == "applied":
        if record["action"] == "adopt":
            bad = _agreement(rd, record, exported=False)
            if bad:
                raise SystemExit(f"[stage] the adoption of `{run_id}` does not agree with its record: " + "; ".join(bad))
            return _set_status(rd, record, "exported", export_id=(jsonl.read_json(rd / "handoff" / "manifest.json", {}) or {}).get("export_id"),
                               manifest_sha256=_sha(rd / "handoff" / "manifest.json"), stages_sha256=stages.stages_sha256(rd))
        if handoff.code_digest()["digest"] != record["rows"][1]["code_baseline"]["code"]["digest"]:
            raise _refuse(f"continuing the transition `{record['transition_id']}`",
                          "the code of this checkout is not the new stage's baseline")
        return _export(run_id, rd, record)
    if status in ("exported", "done"):
        bad = _agreement(rd, record, exported=status == "exported")
        if status == "done":
            bad += _commit_problems(record, record.get("commit"))
        if bad:
            raise SystemExit(f"[stage] the transition `{record['transition_id']}` does not agree with the run: " + "; ".join(bad))
        if status == "done":
            _export_done(run_id, rd)
        return record
    raise SystemExit(f"[stage] the transition `{record.get('transition_id')}` has the unknown state {status!r}")


def _begun(rd: Path, transition: str, action: str, **same) -> dict | None:
    """The record of `transition` when it is the run's last transition (refused when it was begun as
    another action or with other arguments), or None; refused while another transition is unfinished."""
    record = stages.transition_state(rd)
    if record is None:
        return None
    if record.get("transition_id") == transition:
        diff = [k for k, v in same.items() if record.get(k) != v]
        if record.get("action") != action or diff:
            raise _refuse(f"the transition `{transition}`", f"it was begun as `{record.get('action')}` with other "
                          f"arguments ({', '.join(diff) or 'action'})")
        return record
    why = stages.transition_refusal(rd)
    if why:
        raise _refuse(f"the transition `{transition}`", why)
    return None


def _report(record: dict) -> dict:
    s = record["status"]
    print(f"stage transition {record['transition_id']}: {record.get('from') or '-'} → {record['to']}, {s}"
          + ("; commit and push the run branch, then `stage confirm`" if s == "exported" else ""))
    return record


def enter(run_id: str, kind: str, from_id: str, transition: str, scope: str | None = None,
          prompts_approved: str | None = None, source_commit: str | None = None) -> dict:
    """Close the active stage `from_id` and open a stage of `kind` on this checkout's code (see the
    module's description). Returns the transition record."""
    if kind == "review":
        raise _refuse("stage enter", stages.REVIEW_REFUSAL)
    if kind not in stages.KINDS:
        raise _refuse("stage enter", f"unknown stage kind {kind!r}")
    if not transition:
        raise _refuse("stage enter", "give --transition")
    rd = paths.run_dir(run_id)
    if not (rd / "options.json").exists():
        raise _refuse("stage enter", f"no run `{run_id}` under {paths.RESULTS}")
    if kind == "labels":
        try:
            was = stages.active_stage(rd)
        except jsonl.DataIntegrityError as e:
            raise _refuse("stage enter", f"the stage record cannot be read ({e})")
        if was is not None and was.get("stage_kind") != "labels":
            raise _refuse("stage enter", stages.LABELS_REFUSAL)
    owner.acquire_for_transition(run_id, transition)
    _finish_journal(rd)
    record = _begun(rd, transition, "enter", **{"from": from_id, "to_kind": kind})
    if record is not None:
        return _report(_continue(run_id, rd, record))
    try:
        rows = stages.read_stages(rd)
    except jsonl.DataIntegrityError as e:
        raise _refuse("stage enter", f"the stage record cannot be read ({e})")
    done_before = [r for r in rows if r.get("transition_id") == transition]
    if done_before:
        raise _refuse("stage enter", f"the transition `{transition}` was completed earlier and another followed it")
    if not rows:
        raise _refuse("stage enter", f"`{run_id}` has no stage record: register it with `stage adopt` first")
    active = rows and next(r for r in reversed(rows) if r.get("event") == "open")
    left = [r for r in rows if r.get("event") == "close" and r.get("stage_id") == from_id]
    if left:
        raise _refuse("stage enter", f"the stage `{from_id}` was already left by the transition `{left[0].get('transition_id')}`")
    if active["stage_id"] != from_id:
        raise _refuse("stage enter", f"the active stage is `{active['stage_id']}`, not `{from_id}`")
    if (active["stage_kind"], kind) not in stages.ALLOWED_TRANSITIONS:
        if kind == "labels":
            raise _refuse("stage enter", stages.LABELS_REFUSAL)
        raise _refuse("stage enter", f"a `{active['stage_kind']}` stage may not be followed by a `{kind}` stage")
    bad = list(handoff.checkpoint_problems(run_id, for_transition=True))
    m = jsonl.read_json(rd / "handoff" / "manifest.json", None)
    if m is None:
        bad.append(f"`{run_id}` has no handoff manifest")
    elif m.get("stage_id") != from_id:
        bad.append(f"the handoff manifest names the stage `{m.get('stage_id')}`, not `{from_id}`: export the run first")
    elif m.get("stages_sha256") != stages.stages_sha256(rd):
        bad.append("the handoff manifest's stages_sha256 is not the stage record's: export the run first")
    snap = jsonl.read_json(rd / "state.json", {}) or {}
    busy = sorted(law for law, st in (snap.get("label_states") or {}).items() if st.get("active"))
    if busy:
        bad.append(f"label repair(s) active: {', '.join(busy[:8])}")
    if snap.get("deferred_concepts"):
        bad.append(f"{len(snap['deferred_concepts'])} concept review(s) deferred")
    if bad:
        raise _refuse("stage enter", bad)
    scope_v, why = new_scope(run_id, active, kind, scope)
    bad += why
    opts = _options(run_id)
    from ..loop import semantic_inputs
    sem = semantic_inputs(opts)
    code = handoff.code_digest()
    now_eff = effects_at(paths.REPO, sem)
    was_eff = active.get("effects")
    if not was_eff:
        bad.append(f"the stage `{from_id}` records no effects to compare with")
        changed = []
    else:
        changed = classify(active["code_baseline"]["code"]["files"], code["files"], was_eff, now_eff,
                           (rd / "comparison_set.json").exists())
        bad += change_refusals(changed, active.get("semantic") or {}, sem, prompts_approved)
    refusals, _warnings = handoff.verify(run_id, artifacts=True, for_transition=True)
    bad += refusals
    source_commit = source_commit or _head(paths.REPO)
    why = baseline_refusal(paths.REPO, source_commit, code["files"])
    if why:
        bad.append(why)
    if bad:
        raise _refuse("stage enter", bad)
    # the closing stage's snapshot, from the run as its last export left it; then the transition's own files
    snapshot.write(run_id, from_id, transition)
    problems = snapshot.verify(run_id, from_id)
    if problems:
        raise SystemExit(f"[stage] the snapshot of `{from_id}` is not whole: " + "; ".join(problems[:8])
                         + " — the transition was not begun")
    ckpt = {"export_id": m.get("export_id"), "manifest_sha256": _sha(rd / "handoff" / "manifest.json"),
            "snapshot_manifest_sha256": _sha(rd / stages.STAGES_DIR / from_id / "manifest.json")}
    to = _next_id(rows, kind)
    close = {"event": "close", "stage_id": from_id, "transition_id": transition, "output_checkpoint": ckpt, "closed_at": _now()}
    opened = {"event": "open", "run_id": run_id, "stage_id": to, "stage_kind": kind, "launch_kinds": list(stages.LAUNCH_KINDS[kind]),
              "previous_stage_id": from_id, "transition_id": transition, "input_checkpoint": ckpt,
              "code_baseline": {"source_commit": source_commit, "code": code}, "state_schema": RUN_VERSION,
              "semantic": sem, "acceptance_policy": active.get("acceptance_policy"), "scope": scope_v, "changed_files": changed,
              "effects": now_eff, "prompts_approved": prompts_approved, "opened_at": _now()}
    record = {"transition_id": transition, "action": "enter", "run_id": run_id, "from": from_id, "to": to, "to_kind": kind,
              "rows": [close, opened]}
    record = _set_status(rd, record, "prepared")
    _commit(rd, record)
    return _report(_export(run_id, rd, stages.transition_state(rd)))


# -- confirm -----------------------------------------------------------------------------------------

def _git(root: Path, *args: str, binary: bool = False):
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=not binary)


def _commit_problems(record: dict, commit: str | None) -> list[str]:
    """How the commit's tree disagrees with the transition's export: the stage record and the handoff
    manifest it holds for the run are the bytes the transition exported."""
    if not commit:
        return ["no commit is recorded"]
    top = _git(paths.REPO, "rev-parse", "--show-toplevel")
    if top.returncode != 0:
        return [f"{paths.REPO} is not a git checkout"]
    rel = paths.run_dir(record["run_id"]).resolve().relative_to(Path(top.stdout.strip()).resolve()).as_posix()
    bad = []
    for name, key in ((stages.STAGES_FILE, "stages_sha256"), ("handoff/manifest.json", "manifest_sha256")):
        p = _git(paths.REPO, "show", f"{commit}:{rel}/{name}", binary=True)
        if p.returncode != 0:
            bad.append(f"the commit {commit[:12]} holds no {rel}/{name}")
        elif hashlib.sha256(p.stdout).hexdigest() != record.get(key):
            bad.append(f"the commit {commit[:12]} holds another {name} than the transition exported")
    return bad


def confirm(run_id: str, transition: str, commit: str, remote: str = "origin", branch: str | None = None) -> dict:
    """Record the transition `done` once `commit` is on the remote run branch (`runs/<run>` unless
    given) and its tree holds the stage record and the manifest the transition exported."""
    rd = paths.run_dir(run_id)
    owner.acquire_for_transition(run_id, transition)
    _finish_journal(rd)
    record = stages.transition_state(rd)
    if record is None or record.get("transition_id") != transition:
        raise _refuse("stage confirm", f"the run's last transition is not `{transition}`")
    if record.get("status") not in ("exported", "done"):
        raise _refuse("stage confirm", f"the transition stopped at `{record.get('status')}`: run it again first")
    if record["status"] == "done":
        return _report(_continue(run_id, rd, record))
    branch = branch or f"runs/{run_id}"
    full = _git(paths.REPO, "rev-parse", "--verify", f"{commit}^{{commit}}")
    if full.returncode != 0:
        raise _refuse("stage confirm", f"no commit {commit} in this checkout")
    full = full.stdout.strip()
    ls = _git(paths.REPO, "ls-remote", "--heads", remote, f"refs/heads/{branch}")
    tip = (ls.stdout.split() or [None])[0] if ls.returncode == 0 else None
    bad = []
    if tip is None:
        bad.append(f"{remote} has no branch {branch}" + (f" ({ls.stderr.strip()[:200]})" if ls.returncode else ""))
    elif _git(paths.REPO, "cat-file", "-e", f"{tip}^{{commit}}").returncode != 0:
        bad.append(f"the tip {tip[:12]} of {remote}/{branch} is not in this checkout: fetch it first")
    elif _git(paths.REPO, "merge-base", "--is-ancestor", full, tip).returncode != 0:
        bad.append(f"the commit {full[:12]} is not on {remote}/{branch}")
    bad += _agreement(rd, record)
    bad += _commit_problems(record, full)
    if bad:
        raise _refuse("stage confirm", bad)
    record = _set_status(rd, record, "done", commit=full, remote=remote, branch=branch)
    _export_done(run_id, rd)
    return _report(record)


def _export_done(run_id: str, rd: Path) -> None:
    """A handoff manifest that lists the transition record with other content than the record now has
    (written before it was `done`) is exported again, so the run on disk is the export it names."""
    m = jsonl.read_json(rd / "handoff" / "manifest.json", {}) or {}
    f = rd / stages.TRANSITION_FILE
    h = (m.get("artifacts") or {}).get(f.resolve().relative_to(paths.REPO.resolve()).as_posix())
    if h is not None and h != _sha(f):
        handoff.export(run_id)


# -- adopt -------------------------------------------------------------------------------------------

def _old_paths(old: Path, run_id: str) -> Path:
    return old / paths.RESULTS.relative_to(paths.REPO) / run_id


def adopt_checks(run_id: str, old: Path) -> tuple[dict | None, list[str]]:
    """The independent checks of a run's checkpoint in its old checkout `old` (its agent directory):
    the old code's own `handoff verify` exits 0; every code file of the old manifest's baseline hashed
    again under `old` and combined as `code_digest` combines them equals the manifest; HEAD descends
    from the manifest's source commit with no merge after it and no change of a code path since.
    Returns the old manifest and the refusals."""
    ord_ = _old_paths(old, run_id)
    m = jsonl.read_json(ord_ / "handoff" / "manifest.json", None)
    if m is None:
        return None, [f"the old checkout holds no handoff manifest of `{run_id}`"]
    bad = []
    if (ord_ / stages.STAGES_FILE).exists() or m.get("stage_id"):
        bad.append(f"`{run_id}` already has a stage record: it is continued with `stage enter`")
    env = {**os.environ, "PYTHONPATH": os.pathsep.join([str(old), *[x for x in os.environ.get("PYTHONPATH", "").split(os.pathsep) if x]])}
    env.pop(owner.ENV, None); env.pop(owner.LIB_ENV, None)
    p = subprocess.run([sys.executable, "-m", "harness", "handoff", "verify", run_id], cwd=old, env=env,
                       capture_output=True, text=True)
    if p.returncode != 0:
        bad.append(f"the old checkout's own `handoff verify` exited {p.returncode}: {(p.stdout + p.stderr).strip()[-600:]}")
    files = (m.get("baseline") or {}).get("code", {}).get("files") or {}
    again = {}
    for rel in files:
        f = old / rel                                      # the doctor's split tool too: beside the old checkout, never this process's
        again[rel] = _sha(f) if f.is_file() else None
    moved = sorted(k for k in files if again[k] != files[k])
    if moved:
        bad.append(f"{len(moved)} code file(s) of the old checkout differ from its manifest: {', '.join(moved[:8])}")
    if hashlib.sha256(json.dumps(again, sort_keys=True).encode()).hexdigest() != (m.get("baseline") or {}).get("code", {}).get("digest"):
        bad.append("the old checkout's code digest, computed again, is not its manifest's")
    src = (m.get("baseline") or {}).get("source_commit")
    if not src:
        bad.append("the old manifest records no source commit")
    else:
        g = lambda *a: _git(old, *a)
        if g("merge-base", "--is-ancestor", src, "HEAD").returncode != 0:
            bad.append(f"the old checkout's HEAD does not descend from the source commit {src[:12]}")
        else:
            merges = g("rev-list", "--merges", f"{src}..HEAD").stdout.split()
            if merges:
                bad.append(f"the old checkout's branch holds merge commit(s) after {src[:12]}: {', '.join(x[:12] for x in merges[:4])}")
            spec = [f":(glob){pat}" for pat in handoff.CODE_PATTERNS]
            if g("diff", "--quiet", src, "HEAD", "--", *spec).returncode != 0:
                bad.append(f"the old checkout's code paths changed since the source commit {src[:12]}")
    return m, bad


def adopt(run_id: str, old_checkout: str, transition: str) -> dict:
    """Register a run made before stages existed as its stage `G0` in this checkout, from its old
    checkout (see the module's description). Returns the transition record."""
    if not transition:
        raise _refuse("stage adopt", "give --transition")
    old = Path(old_checkout).resolve()
    rd = paths.run_dir(run_id)
    if old == paths.REPO.resolve():
        raise _refuse("stage adopt", "the old checkout is this checkout: adopt runs in a new checkout")
    owner.acquire_for_transition(run_id, transition)
    if rd.exists():
        _finish_journal(rd)
        record = stages.transition_state(rd)
        if record is None or record.get("transition_id") != transition or record.get("action") != "adopt":
            raise _refuse("stage adopt", f"this checkout already holds a run `{run_id}`")
        if record.get("status") != "prepared":
            return _report(_continue(run_id, rd, record))
    m, bad = adopt_checks(run_id, old)
    if bad:
        raise _refuse("stage adopt", bad)
    ord_ = _old_paths(old, run_id)
    arts = dict(m.get("artifacts") or {})
    sem = dict(m.get("semantic") or {})
    record = {"transition_id": transition, "action": "adopt", "run_id": run_id, "from": None, "to": "G0", "to_kind": "generation",
              "old_checkout": str(old)}
    opened = {"event": "open", "run_id": run_id, "stage_id": "G0", "stage_kind": "generation",
              "launch_kinds": list(stages.LAUNCH_KINDS["generation"]), "previous_stage_id": None, "transition_id": transition,
              "input_checkpoint": None, "code_baseline": m["baseline"], "state_schema": sem.get("run_version", RUN_VERSION),
              "semantic": sem, "acceptance_policy": {**(m.get("acceptance_policy") or {}), "review": "none"}, "scope": "all",
              "changed_files": [], "effects": effects_at(old, sem), "prompts_approved": None,
              "adopted_from": {"export_id": m.get("export_id"), "manifest_sha256": _sha(ord_ / "handoff" / "manifest.json"),
                               "head": _head(old)},
              "opened_at": _now()}
    record["rows"] = [opened]
    rd.mkdir(parents=True, exist_ok=True)
    record = _set_status(rd, record, "prepared")
    from ..phases import candidate
    for rel, h in sorted(arts.items()):                    # the run's handed files, each as the old export recorded it
        src, dst = old / rel, paths.REPO / rel
        if _sha(src) != h:
            raise SystemExit(f"[stage] {rel} changed in the old checkout while it was adopted — run `stage adopt` again")
        if not dst.is_file() or _sha(dst) != h:
            candidate._replace(src, dst)
    stages_text = _rows_text([opened]).encode()
    srel = (rd / stages.STAGES_FILE).relative_to(paths.REPO).as_posix()
    hd = rd / "handoff"
    manifest = {**m, "export_id": uuid.uuid4().hex, "exported_at": _now(), "stage_id": "G0",
                "stages_sha256": hashlib.sha256(stages_text).hexdigest(), "artifacts": {**arts, srel: hashlib.sha256(stages_text).hexdigest()}}
    listed = sorted(manifest["artifacts"]) + [(hd / "manifest.json").relative_to(paths.REPO).as_posix(),
                                              (hd / "files.txt").relative_to(paths.REPO).as_posix()]
    _commit(rd, record, extra=[(json.dumps(manifest, indent=1, ensure_ascii=False).encode(), hd / "manifest.json"),
                               ("".join(f + "\n" for f in listed).encode(), hd / "files.txt")])
    return _report(_continue(run_id, rd, stages.transition_state(rd)))


# -- show, verify, restore ---------------------------------------------------------------------------

def show(run_id: str) -> int:
    rd = paths.run_dir(run_id)
    rows = stages.read_stages(rd)
    if not rows:
        print(f"`{run_id}` has no stage record")
    for r in rows:
        if r["event"] == "open":
            sc = r.get("scope")
            sc = "all" if sc in (None, "all") else f"{len(sc['laws'])} law(s)"
            print(f"open   {r['stage_id']:4s} {r['stage_kind']:10s} launches {','.join(r.get('launch_kinds', []))}  "
                  f"baseline {(r.get('code_baseline') or {}).get('source_commit') or '-'}  "
                  f"scope {sc}  "
                  f"changed {len(r.get('changed_files') or [])} file(s)  ({r.get('transition_id')}, {r.get('opened_at')})")
        else:
            print(f"close  {r['stage_id']:4s} ({r.get('transition_id')}, {r.get('closed_at')})")
    active = stages.active_stage(rd)
    print(f"active stage: {active['stage_id'] if active else '-'}")
    t = stages.transition_state(rd)
    if t:
        print(f"last transition: {t.get('transition_id')} ({t.get('action')}) {t.get('from') or '-'} → {t.get('to')}: {t.get('status')}")
    return 0


def main(argv: list[str]) -> int:
    """`python -m harness stage <action> ...`: the stage commands, parsed with their flags as written
    (a flag of two words may be spelled with a hyphen or, as the harness's other options, an underscore)."""
    ap = argparse.ArgumentParser(prog="python -m harness stage")
    sub = ap.add_subparsers(dest="action", required=True)
    e = sub.add_parser("enter"); e.add_argument("run")
    e.add_argument("--kind", required=True); e.add_argument("--from", dest="from_id", required=True)
    e.add_argument("--transition", required=True); e.add_argument("--scope")
    e.add_argument("--prompts-approved", "--prompts_approved", dest="prompts_approved")
    e.add_argument("--source-commit", "--source_commit", dest="source_commit")
    a = sub.add_parser("adopt"); a.add_argument("run")
    a.add_argument("--old-checkout", "--old_checkout", dest="old_checkout", required=True); a.add_argument("--transition", required=True)
    c = sub.add_parser("confirm"); c.add_argument("run")
    c.add_argument("--transition", required=True); c.add_argument("--commit", required=True)
    c.add_argument("--remote", default="origin"); c.add_argument("--branch")
    v = sub.add_parser("verify"); v.add_argument("run"); v.add_argument("stage_id", nargs="?")
    r = sub.add_parser("restore"); r.add_argument("run"); r.add_argument("stage_id"); r.add_argument("--into", required=True)
    s = sub.add_parser("show"); s.add_argument("run")
    o = ap.parse_args(argv)
    if o.action == "enter":
        enter(o.run, o.kind, o.from_id, o.transition, o.scope, o.prompts_approved, o.source_commit); return 0
    if o.action == "adopt":
        adopt(o.run, o.old_checkout, o.transition); return 0
    if o.action == "confirm":
        confirm(o.run, o.transition, o.commit, o.remote, o.branch); return 0
    if o.action == "verify":
        problems = snapshot.verify(o.run, o.stage_id)
        for x in problems:
            print(f"refused  {x}")
        print("not verified" if problems else "verified")
        return 1 if problems else 0
    if o.action == "restore":
        snapshot.restore(o.run, o.stage_id, Path(o.into))
        print(f"restored `{o.run}` as stage {o.stage_id} left it into {o.into}"); return 0
    return show(o.run)
